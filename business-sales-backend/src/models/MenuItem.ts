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
  isAvailable: {
    type: Boolean,
    default: true
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

export default mongoose.model<IMenuItem>('MenuItems', MenuItemSchema); 