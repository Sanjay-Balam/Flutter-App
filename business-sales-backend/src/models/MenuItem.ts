import mongoose, { Schema, Document } from 'mongoose';
import type { MenuItem as IMenuItem } from '../types';
import { MenuCategory, ItemSize } from '../types';

export interface MenuItemDocument extends Omit<IMenuItem, 'id'>, Document {
  _id: string;
}

const MenuItemSchema = new Schema<MenuItemDocument>({
  id: {
    type: String,
    required: true,
    unique: true,
    default: () => new mongoose.Types.ObjectId().toString()
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
  timestamps: true,
  toJSON: {
    transform: function(doc: any, ret: any) {
      ret.id = ret.id || ret._id.toString();
      delete ret._id;
      delete ret.__v;
      
      // Convert Map to Object for JSON serialization
      if (ret.prices instanceof Map) {
        ret.prices = Object.fromEntries(ret.prices);
      }
      
      return ret;
    }
  }
});

// Indexes for better query performance
MenuItemSchema.index({ category: 1 });
MenuItemSchema.index({ isAvailable: 1 });
MenuItemSchema.index({ name: 'text', description: 'text' });

// Pre-save middleware to generate ID if not provided
MenuItemSchema.pre('save', function(next) {
  if (!this.id) {
    this.id = new mongoose.Types.ObjectId().toString();
  }
  next();
});

export const MenuItemModel = mongoose.model<MenuItemDocument>('MenuItem', MenuItemSchema); 