import { NotFoundError } from './SearchService';
import searchService from './SearchService';

// Type definitions for proper typing
interface SaleItem {
  menuItemId: string;
  itemName: string;
  categoryId: string;
  categoryName: string;
  size: string;
  unitPrice: number;
  quantity: number;
  subtotal: number;
}

interface SaleRecord {
  _id: string;
  userId: string;
  // Single-item fields
  menuItemId?: string;
  menuItem?: string;
  itemName?: string;
  categoryId?: string;
  categoryName?: string;
  size?: string;
  unitPrice?: number;
  quantity?: number;
  // Multi-item fields
  items?: SaleItem[];
  saleType: 'single' | 'multi';
  // Shared fields
  totalAmount: number;
  taxAmount?: number;
  grandTotal: number;
  timestamp: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
  invoiceGenerated?: boolean;
  invoiceNumber?: string;
  invoiceGeneratedAt?: Date;
  paymentMethod?: string;
  paymentStatus?: string;
  [key: string]: any;
}

interface User {
  _id: string;
  firstName: string;
  lastName: string;
  email: string;
  businessDetails?: {
    address?: any;
    contact?: any;
    tax?: any;
    branding?: any;
  };
  invoiceSettings?: {
    prefix?: string;
    nextNumber?: number;
    includeNotes?: boolean;
    includeTax?: boolean;
    taxRate?: number;
  };
  [key: string]: any;
}

export interface InvoiceData {
  invoiceNumber: string;
  saleRecord: SaleRecord;
  businessDetails: User['businessDetails'];
  invoiceSettings: User['invoiceSettings'];
  generatedAt: Date;
}

class InvoiceService {
  
  /**
   * Generate invoice number and update sale record
   */
  async generateInvoiceForSale(database: string, saleId: string, userId: string): Promise<InvoiceData> {
    try {
      // 1. Get user details for invoice settings using SearchService
      const userResult = await searchService.getResource(database, 'Users', { id: userId });
      
      if (!userResult || !userResult.success || !userResult.data) {
        throw new NotFoundError('User not found');
      }
      
      const user = userResult.data as unknown as User;

      // 2. Ensure user has complete invoice settings - fix root cause
      if (!user.invoiceSettings || !user.invoiceSettings.prefix) {
        const defaultInvoiceSettings = {
          prefix: 'INV',
          nextNumber: 1,
          includeNotes: true,
          includeTax: false,
          taxRate: 0
        };
        
        // Update user with proper invoice settings
        await searchService.updateResource(database, 'Users', { id: userId }, {
          invoiceSettings: defaultInvoiceSettings
        });
        
        // Update local user object
        user.invoiceSettings = defaultInvoiceSettings;
      }

      // 3. Get sale record using SearchService
      const saleResult = await searchService.getResource(database, 'SaleRecords', { id: saleId });
      if (!saleResult || !saleResult.success || !saleResult.data) {
        throw new NotFoundError('Sale record not found');
      }
      
      const saleRecord = saleResult.data as unknown as SaleRecord;

      // Check if invoice already generated
      if (saleRecord.invoiceGenerated) {
        return {
          invoiceNumber: saleRecord.invoiceNumber!,
          saleRecord: saleRecord,
          businessDetails: user.businessDetails || {},
          invoiceSettings: user.invoiceSettings || {},
          generatedAt: saleRecord.invoiceGeneratedAt || new Date()
        };
      }

      // 4. Generate invoice number (now we know invoiceSettings are always valid)
      const { prefix = 'INV', nextNumber = 1 } = user.invoiceSettings!;
      const invoiceNumber = `${prefix}-${String(nextNumber).padStart(4, '0')}`;

      // 4. Update sale record with invoice info using SearchService
      const updatedSaleData = {
        ...saleRecord,
        invoiceNumber,
        invoiceGenerated: true,
        invoiceGeneratedAt: new Date()
      };
      
      await searchService.updateResource(database, 'SaleRecords', { id: saleId }, {
        invoiceNumber,
        invoiceGenerated: true,
        invoiceGeneratedAt: new Date()
      });

      // 5. Increment invoice counter for user
      const newInvoiceSettings = {
        ...user.invoiceSettings,
        nextNumber: nextNumber + 1
      };
      await searchService.updateResource(database, 'Users', { id: userId }, {
        invoiceSettings: newInvoiceSettings
      });

      return {
        invoiceNumber,
        saleRecord: updatedSaleData,
        businessDetails: user.businessDetails || {},
        invoiceSettings: user.invoiceSettings,
        generatedAt: new Date()
      };

    } catch (error: any) {
      console.error('Invoice generation error:', error);
      throw error;
    }
  }

  /**
   * Get invoice data by sale ID
   */
  async getInvoiceData(database: string, saleId: string): Promise<InvoiceData | null> {
    try {
      const saleResult = await searchService.getResource(database, 'SaleRecords', { id: saleId });
      if (!saleResult || !saleResult.success || !saleResult.data) {
        return null;
      }
      
      const saleRecord = saleResult.data as unknown as SaleRecord;
      
      if (!saleRecord.invoiceGenerated) {
        return null;
      }

      const userResult = await searchService.getResource(database, 'Users', { id: saleRecord.userId });
      if (!userResult || !userResult.success || !userResult.data) {
        throw new NotFoundError('User not found');
      }
      
      const user = userResult.data as unknown as User;

      return {
        invoiceNumber: saleRecord.invoiceNumber!,
        saleRecord: saleRecord,
        businessDetails: user.businessDetails || {},
        invoiceSettings: user.invoiceSettings || {},
        generatedAt: saleRecord.invoiceGeneratedAt || new Date()
      };

    } catch (error: any) {
      console.error('Get invoice data error:', error);
      throw error;
    }
  }

  /**
   * Get all invoices for a user with pagination
   */
  async getUserInvoices(database: string, userId: string, page: number = 1, pageSize: number = 20) {
    try {
      // Note: This is a simplified implementation
      // In a real application, you might want to implement proper pagination in SearchService
      const result = await searchService.searchResource(database, 'SaleRecords', {
        query: {
          userId: userId,
          invoiceGenerated: true
        },
        limit: pageSize * 3, // Get more records to handle pagination client-side
        offset: 0
      });

      if (!result || !result.success || !result.data) {
        return {
          success: false,
          error: 'Failed to get invoices'
        };
      }

      // Simple client-side pagination (not optimal for large datasets)
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
      console.error('Get user invoices error:', error);
      return { 
        success: false, 
        error: error.message || 'Failed to get invoices' 
      };
    }
  }

  /**
   * Update business details for invoices
   */
  async updateBusinessDetails(database: string, userId: string, businessDetails: any) {
    try {
      const result = await searchService.updateResource(database, 'Users', { id: userId }, {
        businessDetails
      });

      if (!result || !result.success) {
        throw new NotFoundError('User not found');
      }

      return {
        success: true,
        data: result.data?.businessDetails
      };

    } catch (error: any) {
      console.error('Update business details error:', error);
      return { 
        success: false, 
        error: error.message || 'Failed to update business details' 
      };
    }
  }

  /**
   * Update invoice settings
   */
  async updateInvoiceSettings(database: string, userId: string, invoiceSettings: any) {
    try {
      const result = await searchService.updateResource(database, 'Users', { id: userId }, {
        invoiceSettings
      });

      if (!result || !result.success) {
        throw new NotFoundError('User not found');
      }

      return {
        success: true,
        data: result.data?.invoiceSettings
      };

    } catch (error: any) {
      console.error('Update invoice settings error:', error);
      return { 
        success: false, 
        error: error.message || 'Failed to update invoice settings' 
      };
    }
  }
}

export default new InvoiceService();
