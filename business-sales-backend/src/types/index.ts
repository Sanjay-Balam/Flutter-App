// Enums matching Flutter app
export enum MenuCategory {
  MILK_CAKES = 'milkCakes',
  CHEESE_CAKES = 'cheeseCakes',
  CHOCOLATE_BROWNIE = 'chocolateBrownie'
}

export enum ItemSize {
  SMALL = 'small',
  LARGE = 'large',
  REGULAR = 'regular'
}

export enum UserRole {
  OWNER = 'owner',
  MANAGER = 'manager',
  EMPLOYEE = 'employee'
}

// User Interface
export interface User {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  password: string;
  role: UserRole;
  businessName?: string;
  businessType?: string;
  isActive: boolean;
  avatar?: string;
  address?: {
    street?: string;
    city?: string;
    state?: string;
    country?: string;
    zipCode?: string;
  };
  preferences?: {
    currency: string;
    timezone: string;
    notifications: {
      email: boolean;
      push: boolean;
      sms: boolean;
    };
  };
  lastLoginAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

// Menu Item Interface
export interface MenuItem {
  id: string;
  name: string;
  category: MenuCategory;
  prices: Record<ItemSize, number>;
  description?: string;
  isAvailable: boolean;
  userId: string; // Reference to User._id
  createdAt?: Date;
  updatedAt?: Date;
}

// Sale Record Interface
export interface SaleRecord {
  id: string;
  menuItemId: string;
  itemName: string;
  category: MenuCategory;
  size: ItemSize;
  unitPrice: number;
  quantity: number;
  totalAmount: number;
  timestamp: Date;
  notes?: string;
  userId: string; // Reference to User._id
  createdAt?: Date;
  updatedAt?: Date;
}

// API Response Types
export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: string;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// Analytics Types
export interface RevenueAnalytics {
  today: number;
  thisWeek: number;
  thisMonth: number;
  thisYear: number;
}

export interface SalesAnalytics {
  totalSales: number;
  totalItems: number;
  averageSale: number;
  topSellingItems: Array<{
    itemName: string;
    quantity: number;
    revenue: number;
  }>;
}

export interface CategoryAnalytics {
  category: MenuCategory;
  sales: number;
  revenue: number;
  percentage: number;
}

export interface AnalyticsResponse {
  revenue: RevenueAnalytics;
  sales: SalesAnalytics;
  categories: CategoryAnalytics[];
  dailyTrends: Array<{
    date: string;
    sales: number;
    revenue: number;
  }>;
}

// Request Body Types
export interface CreateSaleRequest {
  menuItemId: string;
  size: ItemSize;
  quantity: number;
  notes?: string;
  userId: string;
}

export interface UpdateMenuItemRequest {
  name?: string;
  category?: MenuCategory;
  prices?: Record<ItemSize, number>;
  description?: string;
  isAvailable?: boolean;
}

export interface CreateUserRequest {
  firstName: string;
  lastName: string;
  email: string;
  phone?: string;
  password: string;
  role?: UserRole;
  businessName?: string;
  businessType?: string;
}

export interface UpdateUserRequest {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  businessName?: string;
  businessType?: string;
  isActive?: boolean;
  address?: {
    street?: string;
    city?: string;
    state?: string;
    country?: string;
    zipCode?: string;
  };
  preferences?: {
    currency?: string;
    timezone?: string;
    notifications?: {
      email?: boolean;
      push?: boolean;
      sms?: boolean;
    };
  };
} 