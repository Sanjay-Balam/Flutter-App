import mongoose, { Schema, Document, type InferSchemaType } from 'mongoose';
import { MenuCategory, ItemSize } from '../types';

const MenuItemSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'Users',
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  categoryId: {
    type: Schema.Types.ObjectId,
    required: true,
    ref: 'Categories'
  },
  // Legacy field for backwards compatibility (to be removed after migration)
  category: {
    type: String,
    enum: Object.values(MenuCategory),
    required: false // Made optional for migration
  },
  prices: {
    type: Map,
    of: Number,
    required: true,
    validate: {
      validator: function(prices: Map<string, number>) {
        // Ensure at least one price is provided
        return prices.size > 0;
      },
      message: 'At least one price must be provided'
    }
  },
  description: {
    type: String,
    trim: true,
    maxlength: 300
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  stockQuantity: {
    type: Number,
    default: 0,
    required: false, // Explicitly optional
    min: [0, 'Stock quantity cannot be negative'],
    validate: {
      validator: function(value: number | undefined) {
        // Allow undefined to use default value
        if (value === undefined) return true;
        return Number.isInteger(value) && value >= 0;
      },
      message: 'Stock quantity must be a non-negative integer'
    }
  },
  lowStockThreshold: {
    type: Number,
    default: 5,
    required: false, // Explicitly optional
    min: [0, 'Low stock threshold cannot be negative']
  },
  trackStock: {
    type: Boolean,
    default: true, // Enable stock tracking by default
    required: false // Explicitly optional
  }
}, {
  timestamps: true
});

// Generate the type from the schema
type MenuItemSchemaType = InferSchemaType<typeof MenuItemSchema>;

// Create the interface extending Document and the schema type
interface IMenuItem extends MenuItemSchemaType, Document { }

// Indexes for better query performance
MenuItemSchema.index({ categoryId: 1 }); // New index for dynamic categories
MenuItemSchema.index({ userId: 1, categoryId: 1 }); // Compound index for user's category items
MenuItemSchema.index({ isAvailable: 1 });
MenuItemSchema.index({ name: 'text', description: 'text' });
// Legacy index (to be removed after migration)
MenuItemSchema.index({ category: 1 });


export default mongoose.model<IMenuItem>('MenuItems', MenuItemSchema, 'MenuItems'); 