import mongoose, { Schema, Document, type InferSchemaType } from 'mongoose';

const CategorySchema = new Schema({
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
    maxlength: 50,
    unique: false // Allow same name across different users
  },
  description: {
    type: String,
    trim: true,
    maxlength: 200
  },
  icon: {
    type: String,
    trim: true,
  },
  color: {
    type: String,
    trim: true,
  },
  isActive: {
    type: Boolean,
    default: true
  },
  sortOrder: {
    type: Number,
    default: 0,
    min: 0
  }
}, {
  timestamps: true
});

// Generate the type from the schema
type CategorySchemaType = InferSchemaType<typeof CategorySchema>;

// Create the interface extending Document and the schema type
interface ICategory extends CategorySchemaType, Document {}

// Indexes for better query performance
CategorySchema.index({ userId: 1, name: 1 }, { unique: true }); // Unique per user
CategorySchema.index({ userId: 1, sortOrder: 1 }); // For ordered retrieval
CategorySchema.index({ userId: 1, isActive: 1 }); // For filtering active categories
CategorySchema.index({ name: 'text', description: 'text' }); // Text search




export default mongoose.model<ICategory>('Categories', CategorySchema, 'Categories');
