import mongoose, { Schema, Document, type InferSchemaType } from 'mongoose';
import { MenuCategory, ItemSize } from '../types';

const SaleRecordSchema = new Schema({
  menuItemId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'MenuItems'
  },
  userId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'Users',
    index: true
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
  }
},{
  timestamps: true
});

// Generate the type from the schema
type SaleRecordSchemaType = InferSchemaType<typeof SaleRecordSchema>;

// Create the interface extending Document and the schema type
interface ISaleRecord extends SaleRecordSchemaType, Document { }

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

export default mongoose.model<ISaleRecord>('SaleRecords', SaleRecordSchema); 