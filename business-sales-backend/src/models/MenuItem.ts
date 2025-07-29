import mongoose, { Schema, Document, type InferSchemaType } from 'mongoose';
import { MenuCategory, ItemSize } from '../types';

const MenuItemSchema = new Schema({
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  category: {
    type: String,
    required: true,
    enum: Object.values(MenuCategory)
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
    maxlength: 500
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  userId: {
    type: String,
    required: true,
    ref: 'User',
    index: true
  }
}, {
  timestamps: true
});

// Generate the type from the schema
type MenuItemSchemaType = InferSchemaType<typeof MenuItemSchema>;

// Create the interface extending Document and the schema type
interface IMenuItem extends MenuItemSchemaType, Document { }

// Indexes for better query performance
MenuItemSchema.index({ category: 1 });
MenuItemSchema.index({ isAvailable: 1 });
MenuItemSchema.index({ name: 'text', description: 'text' });

export default mongoose.model<IMenuItem>('MenuItem', MenuItemSchema); 