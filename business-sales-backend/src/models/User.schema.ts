import mongoose, { Schema, Document, type InferSchemaType } from 'mongoose';

const UserSchema = new Schema({
  firstName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  phone: {
    type: String,
    trim: false,
    match: [/^[\+]?[1-9][\d]{0,15}$/, 'Please enter a valid phone number']
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
    select: false // Don't include password in queries by default
  },
  role: {
    type: String,
    required: true,
    enum: ['owner', 'manager', 'employee'],
    default: 'owner'
  },
  businessName: {
    type: String,
    trim: true,
    maxlength: 100
  },
  businessType: {
    type: String,
    trim: true,
    maxlength: 50,
    default: 'bakery'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Business Details for Invoice Generation
  businessDetails: {
    address: {
      street: { type: String, trim: true },
      city: { type: String, trim: true },
      state: { type: String, trim: true },
      zipCode: { type: String, trim: true },
      country: { type: String, trim: true, default: 'India' }
    },
    contact: {
      phone: { type: String, trim: true },
      email: { type: String, trim: true, lowercase: true },
      website: { type: String, trim: true }
    },
    tax: {
      gstNumber: { type: String, trim: true },
      panNumber: { type: String, trim: true },
      taxRegistered: { type: Boolean, default: false }
    },
    branding: {
      logo: { type: String, trim: true }, // Logo URL or base64
      tagline: { type: String, trim: true, maxlength: 100 },
      primaryColor: { type: String, trim: true, default: '#8D4E23' }
    }
  },
  // Invoice Settings
  invoiceSettings: {
    prefix: { type: String, trim: true, default: 'INV' },
    nextNumber: { type: Number, default: 1 },
    includeNotes: { type: Boolean, default: true },
    includeTax: { type: Boolean, default: false },
    taxRate: { type: Number, default: 0, min: 0, max: 100 }
  }
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc: any, ret: any) {
      ret.id = ret.id || ret._id.toString();
      delete ret._id;
      delete ret.__v;
      delete ret.password; // Never include password in JSON output
      return ret;
    }
  }
});

// Generate the type from the schema
type UserSchemaType = InferSchemaType<typeof UserSchema>;

// Create the interface extending Document and the schema type
interface IUser extends UserSchemaType, Document {
  fullName: string;
  comparePassword(candidatePassword: string): Promise<boolean>;
}

// Indexes for better query performance
UserSchema.index({ role: 1 });
UserSchema.index({ isActive: 1 });
UserSchema.index({ businessName: 'text', firstName: 'text', lastName: 'text' });

// Virtual for full name
UserSchema.virtual('fullName').get(function(this: any) {
  return `${this.firstName} ${this.lastName}`;
});

// Pre-save middleware to hash password
UserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    // In a real app, you'd use bcrypt here
    // For now, we'll just store it as is (NOT recommended for production)
    // const bcrypt = require('bcrypt');
    // this.password = await bcrypt.hash(this.password, 12);
    next();
  } catch (error: any) {
    next(error);
  }
});

// Instance method to compare password
UserSchema.methods.comparePassword = async function(candidatePassword: string): Promise<boolean> {
  // In a real app, you'd use bcrypt here
  // return await bcrypt.compare(candidatePassword, this.password);
  return candidatePassword === this.password;
};

export default mongoose.model<IUser>('Users', UserSchema);
