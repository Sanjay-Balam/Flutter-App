import mongoose, { Schema, Document } from 'mongoose';
import type { SaleRecord as ISaleRecord } from '../types';
import { MenuCategory, ItemSize } from '../types';

export interface SaleRecordDocument extends Omit<ISaleRecord, 'id'>, Document {
  _id: string;
}

const SaleRecordSchema = new Schema<SaleRecordDocument>({
  id: {
    type: String,
    required: true,
    unique: true,
    default: () => new mongoose.Types.ObjectId().toString()
  },
  menuItemId: {
    type: String,
    required: true,
    ref: 'MenuItem'
  },
  itemName: {
    type: String,
    required: true,
    trim: true
  },
  category: {
    type: String,
    required: true,
    enum: Object.values(MenuCategory)
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
  totalAmount: {
    type: Number,
    required: true,
    min: 0
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
  userId: {
    type: String,
    required: true,
    ref: 'User',
    index: true
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc: any, ret: any) {
      ret.id = ret.id || ret._id.toString();
      delete ret._id;
      delete ret.__v;
      return ret;
    }
  }
});

// Indexes for analytics and queries
SaleRecordSchema.index({ timestamp: -1 }); // Latest sales first
SaleRecordSchema.index({ menuItemId: 1 });
SaleRecordSchema.index({ category: 1 });
SaleRecordSchema.index({ timestamp: 1, category: 1 }); // Compound index for analytics

// Create date-based indexes for faster analytics
SaleRecordSchema.index({ 
  timestamp: 1,
  category: 1,
  totalAmount: 1 
});

// Pre-save middleware to calculate totalAmount and generate ID
SaleRecordSchema.pre('save', function(next) {
  if (!this.id) {
    this.id = new mongoose.Types.ObjectId().toString();
  }
  
  // Auto-calculate totalAmount if not provided
  if (!this.totalAmount || this.totalAmount === 0) {
    this.totalAmount = this.unitPrice * this.quantity;
  }
  
  next();
});

// Validation middleware
SaleRecordSchema.pre('save', function(next) {
  // Ensure totalAmount matches unitPrice * quantity
  const calculatedTotal = this.unitPrice * this.quantity;
  const tolerance = 0.01; // Allow for small floating point differences
  
  if (Math.abs(this.totalAmount - calculatedTotal) > tolerance) {
    const error = new Error('Total amount must equal unit price × quantity');
    return next(error);
  }
  
  next();
});

export const SaleRecordModel = mongoose.model<SaleRecordDocument>('SaleRecord', SaleRecordSchema); 