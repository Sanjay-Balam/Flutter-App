import mongoose, { Schema, Document, type InferSchemaType } from 'mongoose';

// Stock movement types
export enum StockMovementType {
  INITIAL = 'INITIAL',           // Initial stock entry
  RESTOCK = 'RESTOCK',           // Adding new stock
  SALE = 'SALE',                 // Stock sold
  ADJUSTMENT = 'ADJUSTMENT',     // Manual adjustment
  RETURN = 'RETURN',             // Item returned
  DAMAGE = 'DAMAGE',             // Damaged/expired items
  TRANSFER = 'TRANSFER'          // Stock transfer
}

const StockHistorySchema = new Schema({
  menuItemId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'MenuItems',
    index: true
  },
  userId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'Users',
    index: true
  },
  movementType: {
    type: String,
    enum: Object.values(StockMovementType),
    required: true
  },
  quantityChange: {
    type: Number,
    required: true,
    validate: {
      validator: function(value: number) {
        return Number.isInteger(value) && value !== 0;
      },
      message: 'Quantity change must be a non-zero integer'
    }
  },
  previousQuantity: {
    type: Number,
    required: true,
    min: 0
  },
  newQuantity: {
    type: Number,
    required: true,
    min: 0
  },
  reason: {
    type: String,
    trim: true,
    maxlength: 200
  },
  saleId: {
    type: Schema.Types.ObjectId,
    ref: 'SaleRecords',
    required: false // Only for SALE movements
  },
  performedBy: {
    type: Schema.Types.ObjectId,
    ref: 'Users',
    required: false // Can be null for automated movements
  }
}, {
  timestamps: true
});

// Generate the type from the schema
type StockHistorySchemaType = InferSchemaType<typeof StockHistorySchema>;

// Create the interface extending Document and the schema type
interface IStockHistory extends StockHistorySchemaType, Document {}

// Indexes for better query performance
StockHistorySchema.index({ menuItemId: 1, createdAt: -1 }); // Get history for an item
StockHistorySchema.index({ userId: 1, createdAt: -1 }); // Get user's stock history
StockHistorySchema.index({ movementType: 1 }); // Filter by movement type
StockHistorySchema.index({ createdAt: -1 }); // Sort by date

export default mongoose.model<IStockHistory>('StockHistory', StockHistorySchema, 'StockHistory');

