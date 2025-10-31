import mongoose, { Schema, Document, type InferSchemaType } from 'mongoose';
import { MenuCategory, ItemSize } from '../types';

// Sale Item Schema - for multi-item sales
const SaleItemSchema = new Schema({
  menuItemId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'MenuItems'
  },
  itemName: {
    type: String,
    required: true,
    trim: true
  },
  categoryId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'Categories'
  },
  categoryName: {
    type: String,
    required: true,
    trim: true
  },
  size: {
    type: String,
    required: true,
    enum: Object.values(ItemSize)
  },
  unitPrice: {
    type: Number,
    required: true,
    min: 0
  },
  quantity: {
    type: Number,
    required: true,
    min: 1
  },
  subtotal: {
    type: Number,
    required: true,
    min: 0
  }
}, { _id: false });

const SaleRecordSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'Users',
    index: true
  },
  // Single-item fields (for backward compatibility and quick sales)
  menuItemId: {
    type: Schema.Types.ObjectId,
    ref: 'MenuItems'
  },
  itemName: {
    type: String,
    trim: true
  },
  categoryId: {
    type: Schema.Types.ObjectId,
    ref: 'Categories'
  },
  categoryName: {
    type: String,
    trim: true,
    maxlength: 50
  },
  size: {
    type: String,
    enum: Object.values(ItemSize)
  },
  unitPrice: {
    type: Number,
    min: 0
  },
  quantity: {
    type: Number,
    min: 1
  },
  // Multi-item fields (for POS/billing transactions)
  items: {
    type: [SaleItemSchema],
    validate: {
      validator: function(this: any, items: any[]) {
        // If items array exists, it must have at least one item
        // If it doesn't exist, single-item fields must be present
        if (items && items.length > 0) return true;
        if (!items || items.length === 0) {
          return this.menuItemId != null;
        }
        return false;
      },
      message: 'Sale must have either items array or single item fields'
    }
  },
  // Shared fields
  totalAmount: {
    type: Number,
    required: true,
    min: 0
  },
  taxAmount: {
    type: Number,
    default: 0,
    min: 0,
    required: false // Make it explicitly optional
  },
  grandTotal: {
    type: Number,
    min: 0,
    required: false // Make it optional for backward compatibility
  },
  timestamp: {
    type: Date,
    default: Date.now,
    required: true
  },
  notes: {
    type: String,
    trim: true,
    maxlength: 500
  },
  // Invoice tracking fields
  invoiceNumber: {
    type: String,
    trim: true,
    index: true,
    unique: true,
    sparse: true // Allows null values but enforces uniqueness when present
  },
  invoiceGenerated: {
    type: Boolean,
    default: false
  },
  invoiceGeneratedAt: {
    type: Date
  },
  // Payment information
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'upi', 'other'],
    default: 'cash'
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'partially_paid', 'refunded'],
    default: 'paid'
  },
  // Type indicator
  saleType: {
    type: String,
    enum: ['single', 'multi'],
    required: true,
    default: function(this: any) {
      return this.items && this.items.length > 0 ? 'multi' : 'single';
    }
  }
},{
  timestamps: true
});

// Pre-save hook to ensure grandTotal is set for old records
SaleRecordSchema.pre('save', function(next) {
  // If grandTotal is not set, calculate it
  if (this.grandTotal == null || this.grandTotal === undefined) {
    const taxAmount = this.taxAmount || 0;
    this.grandTotal = this.totalAmount + taxAmount;
  }
  next();
});

// Post-find hooks to ensure grandTotal is present for old records when reading
const ensureGrandTotal = function(doc: any) {
  if (doc && (doc.grandTotal == null || doc.grandTotal === undefined)) {
    const taxAmount = doc.taxAmount || 0;
    doc.grandTotal = doc.totalAmount + taxAmount;
  }
};

SaleRecordSchema.post('find', function(docs) {
  if (Array.isArray(docs)) {
    docs.forEach(ensureGrandTotal);
  }
});

SaleRecordSchema.post('findOne', function(doc) {
  ensureGrandTotal(doc);
});

SaleRecordSchema.post('findOneAndUpdate', function(doc) {
  ensureGrandTotal(doc);
});

// Generate the type from the schema
type SaleRecordSchemaType = InferSchemaType<typeof SaleRecordSchema>;

// Create the interface extending Document and the schema type
interface ISaleRecord extends SaleRecordSchemaType, Document { }


// Indexes for analytics and queries
SaleRecordSchema.index({ timestamp: -1 }); // Latest sales first
SaleRecordSchema.index({ menuItemId: 1 });
SaleRecordSchema.index({ categoryId: 1 }); // New index for dynamic categories
SaleRecordSchema.index({ userId: 1, categoryId: 1 }); // User's category sales
SaleRecordSchema.index({ timestamp: 1, categoryId: 1 }); // Compound index for analytics
SaleRecordSchema.index({ categoryName: 1 }); // Text-based category queries
SaleRecordSchema.index({ saleType: 1 }); // Filter by sale type
SaleRecordSchema.index({ userId: 1, saleType: 1 }); // User's sales by type
SaleRecordSchema.index({ userId: 1, invoiceGenerated: 1 }); // User's invoices

// Legacy indexes (to be removed after migration)
SaleRecordSchema.index({ category: 1 });
SaleRecordSchema.index({ timestamp: 1, category: 1 });

// Create date-based indexes for faster analytics
SaleRecordSchema.index({ 
  timestamp: 1,
  categoryId: 1,
  totalAmount: 1 
});

export default mongoose.model<ISaleRecord>('SaleRecords', SaleRecordSchema); 