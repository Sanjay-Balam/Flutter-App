import { Elysia, t } from 'elysia';
import invoiceService from '../services/InvoiceService';

/**
 * Invoice Management Routes
 * 
 * This module handles all invoice-related operations including:
 * - Invoice generation for sales
 * - Retrieving invoice data
 * - Managing business details for invoices
 * - Invoice settings management
 * - User invoice history
 */

const invoiceRoutes = new Elysia({ prefix: '' })
  
  // ===============================
  // INVOICE GENERATION & RETRIEVAL
  // ===============================
  
  // POST /:database/generate-invoice/:saleId - Generate invoice for a sale
  .post('/:database/generate-invoice/:saleId', async ({ params, body }) => {
    const { database, saleId } = params;
    const { userId } = body;
    
    try {
      const invoiceData = await invoiceService.generateInvoiceForSale(database, saleId, userId);
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
      saleId: t.String()
    }),
    body: t.Object({
      userId: t.String()
    })
  })

  // GET /:database/invoice/:saleId - Get invoice data for a sale
  .get('/:database/invoice/:saleId', async ({ params }) => {
    const { database, saleId } = params;
    
    try {
      const invoiceData = await invoiceService.getInvoiceData(database, saleId);
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
      saleId: t.String()
    })
  })

  // GET /:database/invoices/:userId - Get all invoices for a user
  .get('/:database/invoices/:userId', async ({ params, query }) => {
    const { database, userId } = params;
    const page = query.page ? parseInt(query.page as string) : 1;
    const pageSize = query.pageSize ? parseInt(query.pageSize as string) : 20;
    
    return await invoiceService.getUserInvoices(database, userId, page, pageSize);
  }, {
    params: t.Object({
      database: t.String(),
      userId: t.String()
    }),
    query: t.Optional(t.Object({
      page: t.Optional(t.String()),
      pageSize: t.Optional(t.String())
    }))
  })

  // ===============================
  // BUSINESS SETTINGS MANAGEMENT
  // ===============================

  // PATCH /:database/business-details/:userId - Update business details
  .patch('/:database/business-details/:userId', async ({ params, body }) => {
    const { database, userId } = params;
    return await invoiceService.updateBusinessDetails(database, userId, body);
  }, {
    params: t.Object({
      database: t.String(),
      userId: t.String()
    }),
    body: t.Any()
  })

  // PATCH /:database/invoice-settings/:userId - Update invoice settings
  .patch('/:database/invoice-settings/:userId', async ({ params, body }) => {
    const { database, userId } = params;
    return await invoiceService.updateInvoiceSettings(database, userId, body);
  }, {
    params: t.Object({
      database: t.String(),
      userId: t.String()
    }),
    body: t.Any()
  });

export default invoiceRoutes;
