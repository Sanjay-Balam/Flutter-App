import { Elysia, t } from 'elysia';
import searchService from '../services/SearchService';
import invoiceService from '../services/InvoiceService';

/**
 * Transaction Routes - Multi-item sales and invoicing
 * Now uses the enhanced SaleRecord model with saleType: 'multi'
 */
const transactionRoutes = new Elysia({ prefix: '' })
  
  // ===============================
  // TRANSACTION MANAGEMENT (Multi-item sales)
  // ===============================
  
  // POST /:database/transactions - Create a new multi-item sale
  .post('/:database/transactions', async ({ params, body }) => {
    const { database } = params;
    
    try {
      // Validate items
      if (!body.items || body.items.length === 0) {
        return {
          success: false,
          error: 'Transaction must have at least one item'
        };
      }

      // Calculate totals
      const totalAmount = body.items.reduce((sum: number, item: any) => sum + item.subtotal, 0);
      const taxAmount = body.taxAmount || 0;
      const grandTotal = totalAmount + taxAmount;

      // Create multi-item sale record using SearchService
      const result = await searchService.createResource(database, 'SaleRecords', {
        userId: body.userId,
        items: body.items,
        saleType: 'multi',
        totalAmount,
        taxAmount,
        grandTotal,
        timestamp: body.timestamp ? new Date(body.timestamp) : new Date(),
        notes: body.notes,
        paymentMethod: body.paymentMethod || 'cash',
        paymentStatus: body.paymentStatus || 'paid',
        invoiceGenerated: false
      });

      if (!result || !result.success || !result.data) {
        return {
          success: false,
          error: 'Failed to create transaction'
        };
      }

      return {
        success: true,
        data: result.data
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to create transaction'
      };
    }
  }, {
    params: t.Object({
      database: t.String()
    }),
    body: t.Object({
      userId: t.String(),
      items: t.Array(t.Object({
        menuItemId: t.String(),
        itemName: t.String(),
        categoryId: t.String(),
        categoryName: t.String(),
        size: t.String(),
        unitPrice: t.Number(),
        quantity: t.Number(),
        subtotal: t.Number()
      })),
      notes: t.Optional(t.String()),
      taxAmount: t.Optional(t.Number()),
      paymentMethod: t.Optional(t.String()),
      paymentStatus: t.Optional(t.String()),
      timestamp: t.Optional(t.String())
    }),
    detail: {
      tags: ['Transactions'],
      summary: 'Create a new multi-item sale',
      description: 'Create a sale record with multiple items (saleType: multi)'
    }
  })

  // GET /:database/transactions/:transactionId - Get multi-item sale by ID
  .get('/:database/transactions/:transactionId', async ({ params }) => {
    const { database, transactionId } = params;
    
    try {
      const result = await searchService.getResource(database, 'SaleRecords', { id: transactionId });
      if (!result || !result.success || !result.data) {
        return {
          success: false,
          error: 'Sale record not found'
        };
      }
      
      return {
        success: true,
        data: result.data
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to get sale record'
      };
    }
  }, {
    params: t.Object({
      database: t.String(),
      transactionId: t.String()
    }),
    detail: {
      tags: ['Transactions'],
      summary: 'Get multi-item sale by ID',
      description: 'Get a specific multi-item sale record'
    }
  })

  // GET /:database/transactions/user/:userId - Get all multi-item sales for a user
  .get('/:database/transactions/user/:userId', async ({ params, query }) => {
    const { database, userId } = params;
    const page = query.page ? parseInt(query.page as string) : 1;
    const pageSize = query.pageSize ? parseInt(query.pageSize as string) : 20;
    
    try {
      const result = await searchService.searchResource(database, 'SaleRecords', {
        query: {
          userId: userId,
          saleType: 'multi'
        },
        limit: pageSize * 3,
        offset: 0
      });

      if (!result || !result.success || !result.data) {
        return {
          success: false,
          error: 'Failed to get sales'
        };
      }

      const allSales = Array.isArray(result.data) ? result.data : [result.data];
      const startIndex = (page - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedSales = allSales.slice(startIndex, endIndex);

      return {
        success: true,
        data: paginatedSales,
        pagination: {
          page,
          pageSize,
          total: allSales.length,
          totalPages: Math.ceil(allSales.length / pageSize)
        }
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to get sales'
      };
    }
  }, {
    params: t.Object({
      database: t.String(),
      userId: t.String()
    }),
    query: t.Optional(t.Object({
      page: t.Optional(t.String()),
      pageSize: t.Optional(t.String())
    })),
    detail: {
      tags: ['Transactions'],
      summary: 'Get all multi-item sales for a user',
      description: 'Retrieve paginated list of multi-item sales for a specific user'
    }
  })

  // ===============================
  // INVOICE GENERATION FOR MULTI-ITEM SALES
  // ===============================
  
  // POST /:database/transactions/:transactionId/generate-invoice - Generate invoice for multi-item sale
  .post('/:database/transactions/:transactionId/generate-invoice', async ({ params, body }) => {
    const { database, transactionId } = params;
    const { userId } = body;
    
    try {
      // Use the same invoice service - it works for both single and multi-item sales!
      const invoiceData = await invoiceService.generateInvoiceForSale(
        database,
        transactionId,
        userId
      );
      return {
        success: true,
        data: invoiceData
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to generate invoice'
      };
    }
  }, {
    params: t.Object({
      database: t.String(),
      transactionId: t.String()
    }),
    body: t.Object({
      userId: t.String()
    }),
    detail: {
      tags: ['Transactions'],
      summary: 'Generate invoice for a multi-item sale',
      description: 'Generate and attach an invoice to a multi-item sale record'
    }
  })

  // GET /:database/transactions/:transactionId/invoice - Get invoice for multi-item sale
  .get('/:database/transactions/:transactionId/invoice', async ({ params }) => {
    const { database, transactionId } = params;
    
    try {
      const invoiceData = await invoiceService.getInvoiceData(database, transactionId);
      if (!invoiceData) {
        return {
          success: false,
          error: 'Invoice not found or not generated'
        };
      }
      
      return {
        success: true,
        data: invoiceData
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to get invoice data'
      };
    }
  }, {
    params: t.Object({
      database: t.String(),
      transactionId: t.String()
    }),
    detail: {
      tags: ['Transactions'],
      summary: 'Get invoice data for a multi-item sale',
      description: 'Retrieve invoice information for a multi-item sale'
    }
  })

  // GET /:database/transaction-invoices/:userId - Get all multi-item sale invoices for a user
  .get('/:database/transaction-invoices/:userId', async ({ params, query }) => {
    const { database, userId } = params;
    const page = query.page ? parseInt(query.page as string) : 1;
    const pageSize = query.pageSize ? parseInt(query.pageSize as string) : 20;
    
    try {
      const result = await searchService.searchResource(database, 'SaleRecords', {
        query: {
          userId: userId,
          saleType: 'multi',
          invoiceGenerated: true
        },
        limit: pageSize * 3,
        offset: 0
      });

      if (!result || !result.success || !result.data) {
        return {
          success: false,
          error: 'Failed to get invoices'
        };
      }

      const allInvoices = Array.isArray(result.data) ? result.data : [result.data];
      const startIndex = (page - 1) * pageSize;
      const endIndex = startIndex + pageSize;
      const paginatedInvoices = allInvoices.slice(startIndex, endIndex);

      return {
        success: true,
        data: paginatedInvoices,
        pagination: {
          page,
          pageSize,
          total: allInvoices.length,
          totalPages: Math.ceil(allInvoices.length / pageSize)
        }
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to get invoices'
      };
    }
  }, {
    params: t.Object({
      database: t.String(),
      userId: t.String()
    }),
    query: t.Optional(t.Object({
      page: t.Optional(t.String()),
      pageSize: t.Optional(t.String())
    })),
    detail: {
      tags: ['Transactions'],
      summary: 'Get all multi-item sale invoices for a user',
      description: 'Retrieve paginated list of multi-item sales with invoices'
    }
  });

export default transactionRoutes;

