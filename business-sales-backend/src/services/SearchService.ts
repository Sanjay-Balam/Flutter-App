import mongoose from 'mongoose';
import { MenuItemModel } from '../models/MenuItem';
import { SaleRecordModel } from '../models/SaleRecord';
import { UserModel } from '../models/User.schema';

// Model Map for the business sales application
const modelMap: { [key: string]: mongoose.Model<any> } = {
  MenuItems: MenuItemModel,
  SaleRecords: SaleRecordModel,
  Users: UserModel
};

// Custom Error Classes
class NotFoundError extends Error {
  status: number;
  constructor(message: string) {
    super(message);
    this.name = "NotFoundError";
    this.status = 404;
  }
}

class ValidationError extends Error {
  status: number;
  details: any;
  constructor(message: string, details?: any) {
    super(message);
    this.name = "ValidationError";
    this.status = 400;
    this.details = details;
  }
}

// Cache for database connections
const dbConnections: { [dbName: string]: mongoose.Connection } = {};

// Helper to get or create a connection for a database
export async function getDbConnection(dbName: string): Promise<mongoose.Connection> {
  if (dbConnections[dbName]) return dbConnections[dbName];
  
  const uri = process.env.MONGODB_URI || "mongodb://localhost:27017/business-sales-db";
  
  // Connect to the main server, then useDb for the specific database
  if (mongoose.connection.readyState === 0) {
    await mongoose.connect(uri);
  }
  
  const conn = mongoose.connection.useDb(dbName, { useCache: true });
  dbConnections[dbName] = conn;
  return conn;
}

// Helper to get a model for a specific connection
export function getModel(conn: mongoose.Connection, tableName: string) {
  const schema = modelMap[tableName]?.schema;
  if (!schema) throw new NotFoundError(`No schema for table: ${tableName}`);
  
  // Register model on this connection if not already
  return conn.models[tableName] || conn.model(tableName, schema, tableName);
}

// Helper function to convert strings to ObjectIds and Dates based on schema
function convertStringsToObjectIdsAndDates(obj: any, schema: mongoose.Schema<any>) {
  if (!obj || typeof obj !== "object") return obj;

  for (const key of Object.keys(obj)) {
    const schemaType = schema.path(key);

    // Handle direct ObjectId fields
    if (
      schemaType &&
      (schemaType.instance === "ObjectID" || schemaType.instance === "ObjectId")
    ) {
      if (typeof obj[key] === "string" && mongoose.Types.ObjectId.isValid(obj[key])) {
        obj[key] = new mongoose.Types.ObjectId(obj[key]);
      }
      if (Array.isArray(obj[key])) {
        obj[key] = obj[key].map((v: any) =>
          typeof v === "string" && mongoose.Types.ObjectId.isValid(v)
            ? new mongoose.Types.ObjectId(v)
            : v
        );
      }
    }
    // Handle arrays of ObjectIds
    else if (
      schemaType &&
      schemaType.instance === "Array" &&
      // @ts-ignore
      schemaType.caster &&
      // @ts-ignore
      (schemaType.caster.instance === "ObjectID" || schemaType.caster.instance === "ObjectId")
    ) {
      if (obj[key] && typeof obj[key] === "object") {
        for (const op of ["$in", "$all", "$nin", "$or", "$and"]) {
          if (obj[key][op] && Array.isArray(obj[key][op])) {
            obj[key][op] = obj[key][op].map((v: any) =>
              typeof v === "string" && mongoose.Types.ObjectId.isValid(v)
                ? new mongoose.Types.ObjectId(v)
                : v
            );
          }
        }
      }
    }
    // Handle Date fields
    else if (schemaType && schemaType.instance === "Date") {
      // If the value is a string, convert to Date
      if (typeof obj[key] === "string") {
        obj[key] = new Date(obj[key]);
      }
      // If the value is an object with $gte/$lte/$gt/$lt, convert those
      if (typeof obj[key] === "object" && obj[key] !== null) {
        for (const op of ["$gte", "$lte", "$gt", "$lt", "$eq", "$ne"]) {
          if (obj[key][op] && typeof obj[key][op] === "string") {
            obj[key][op] = new Date(obj[key][op]);
          }
        }
      }
    }
    // Recursively handle nested objects
    else if (typeof obj[key] === "object" && obj[key] !== null) {
      obj[key] = convertStringsToObjectIdsAndDates(obj[key], schema);
    }
  }
  return obj;
}

const searchService = {
  // Create a new resource (menu item or sale record)
  createResource: async (database: string, tableName: string, body: any) => {
    try {
      const conn = await getDbConnection(database);
      const Model = getModel(conn, tableName);
      
      // Convert string ObjectIds to MongoDB ObjectIds before creating the document
      const convertedBody = convertStringsToObjectIdsAndDates(body, Model.schema);
      
      const doc = new Model(convertedBody);
      const result = await doc.save();
      return { success: true, data: result };
    } catch (error: any) {
      if (error.name === "ValidationError") {
        return {
          success: false,
          error: "Validation failed",
          details: error.errors || error.message
        };
      }
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { success: false, error: error.message || "Failed to create resource" };
    }
  },

  // Advanced search with aggregation pipeline and pagination
  searchResource: async (
    database: string,
    tableName: string,
    queryBody: any = {},
    options?: { page?: number; pageSize?: number }
  ) => {
    try {
      // 1. Get the connection and model
      const conn = await getDbConnection(database);
      const Model = getModel(conn, tableName);

      // 2. Extract options from queryBody or options param
      const {
        filter = {},
        sort = { _id: -1 },
        project,
        lookups,
        unwind,
        addFields,
        customStages,
        facet,
        ...rest
      } = queryBody;

      // Convert string ObjectIds in filter to real ObjectIds
      const convertedFilter = convertStringsToObjectIdsAndDates({ ...filter }, Model.schema);

      // Pagination
      const page = options?.page || rest.page || 1;
      const pageSize = options?.pageSize || rest.pageSize || 20;
      const skip = (page - 1) * pageSize;

      // 3. Build the aggregation pipeline dynamically
      const pipeline: any[] = [];

      // $match
      if (convertedFilter && Object.keys(convertedFilter).length > 0) {
        pipeline.push({ $match: convertedFilter });
      }

      // $addFields
      if (addFields) {
        pipeline.push({ $addFields: addFields });
      }

      // $lookup (array of lookups)
      if (Array.isArray(lookups)) {
        for (const lookup of lookups) {
          pipeline.push({ $lookup: lookup });
        }
      }

      // $unwind
      if (unwind) {
        // unwind can be a string or an array of strings
        if (Array.isArray(unwind)) {
          unwind.forEach(u => pipeline.push({ $unwind: u }));
        } else {
          pipeline.push({ $unwind: unwind });
        }
      }

      // $sort
      if (sort) {
        pipeline.push({ $sort: sort });
      }

      // $project
      if (project) {
        pipeline.push({ $project: project });
      }

      // Custom stages (for advanced users)
      if (Array.isArray(customStages)) {
        pipeline.push(...customStages);
      }

      // $facet for pagination and total count
      pipeline.push({
        $facet: {
          data: [
            { $skip: skip },
            { $limit: pageSize }
          ],
          total: [
            { $count: "count" }
          ]
        }
      });

      // 4. Run the aggregation
      const [result] = await Model.aggregate(pipeline);

      // 5. Extract results and total count
      const data = result.data;
      const total = result.total.length > 0 ? result.total[0].count : 0;
      const totalPages = Math.ceil(total / pageSize);

      // 6. Return paginated response
      return {
        success: true,
        data,
        pagination: {
          page,
          pageSize,
          total,
          totalPages
        }
      };
    } catch (error: any) {
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { success: false, error: error.message || "Failed to search resource" };
    }
  },

  // Get a single resource by ID
  getResource: async (database: string, tableName: string, params: any) => {
    try {
      const conn = await getDbConnection(database);
      const Model = getModel(conn, tableName);
      
      // Support both _id and custom id field
      const query = params.id ? 
        (mongoose.Types.ObjectId.isValid(params.id) ? 
          { _id: params.id } : 
          { id: params.id }) :
        params;
      
      const result = await Model.findOne(query).lean();
      if (!result) throw new NotFoundError(`Resource not found with id: ${params.id}`);
      return { success: true, data: result };
    } catch (error: any) {
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { success: false, error: error.message || "Failed to get resource" };
    }
  },

  // Delete a resource by ID
  deleteResource: async (database: string, tableName: string, params: any) => {
    try {
      const conn = await getDbConnection(database);
      const Model = getModel(conn, tableName);
      
      // Support both _id and custom id field
      const query = params.id ? 
        (mongoose.Types.ObjectId.isValid(params.id) ? 
          { _id: params.id } : 
          { id: params.id }) :
        params;
      
      const result = await Model.findOneAndDelete(query);
      if (!result) throw new NotFoundError(`Resource not found with id: ${params.id}`);
      return { success: true, data: result };
    } catch (error: any) {
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { success: false, error: error.message || "Failed to delete resource" };
    }
  },

  // Update a resource by ID
  updateResource: async (database: string, tableName: string, params: any, body: any) => {
    try {
      const conn = await getDbConnection(database);
      const Model = getModel(conn, tableName);
      
      // Convert string ObjectIds to MongoDB ObjectIds before updating
      const convertedBody = convertStringsToObjectIdsAndDates(body, Model.schema);
      
      // Support both _id and custom id field
      const query = params.id ? 
        (mongoose.Types.ObjectId.isValid(params.id) ? 
          { _id: params.id } : 
          { id: params.id }) :
        params;
      
      const result = await Model.findOneAndUpdate(
        query, 
        { $set: convertedBody }, 
        { new: true, runValidators: true }
      );
      
      if (!result) throw new NotFoundError(`Resource not found with id: ${params.id}`);
      return { success: true, data: result };
    } catch (error: any) {
      if (error.name === "ValidationError") {
        return {
          success: false,
          error: "Validation failed",
          details: error.errors || error.message
        };
      }
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { success: false, error: error.message || "Failed to update resource" };
    }
  },

  // Remove specific keys from a document
  removeKeysFromBody: async (database: string, tableName: string, params: any, body: any) => {
    try {
      const conn = await getDbConnection(database);
      const Model = getModel(conn, tableName);
      
      // Support both _id and custom id field
      const query = params.id ? 
        (mongoose.Types.ObjectId.isValid(params.id) ? 
          { _id: params.id } : 
          { id: params.id }) :
        params;
      
      const result = await Model.findOneAndUpdate(query, { $unset: body }, { new: true });
      if (!result) throw new NotFoundError(`Resource not found with id: ${params.id}`);
      return { success: true, data: result };
    } catch (error: any) {
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { success: false, error: error.message || "Failed to remove keys from body" };
    }
  },

  // Get menu item by custom ID
  getMenuItemById: async (database: string, menuItemId: string) => {
    try {
      const conn = await getDbConnection(database);
      const Model = getModel(conn, "MenuItems");
      const result = await Model.findOne({ id: menuItemId });
      if (!result) throw new NotFoundError(`Menu item not found with id: ${menuItemId}`);
      return { success: true, data: result };
    } catch (error: any) {
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { success: false, error: error.message || "Failed to get menu item by id" };
    }
  },

  // Get sales by menu item ID
  getSalesByMenuItemId: async (database: string, menuItemId: string, options?: { page?: number; pageSize?: number }) => {
    try {
      const conn = await getDbConnection(database);
      const Model = getModel(conn, "SaleRecords");
      
      const page = options?.page || 1;
      const pageSize = options?.pageSize || 20;
      const skip = (page - 1) * pageSize;
      
      const [data, total] = await Promise.all([
        Model.find({ menuItemId }).sort({ timestamp: -1 }).skip(skip).limit(pageSize).lean(),
        Model.countDocuments({ menuItemId })
      ]);
      
      return {
        success: true,
        data,
        pagination: {
          page,
          pageSize,
          total,
          totalPages: Math.ceil(total / pageSize)
        }
      };
    } catch (error: any) {
      return { success: false, error: error.message || "Failed to get sales by menu item id" };
    }
  },

  // Direct aggregation pipeline execution
  directAggregation: async (database: string, tableName: string, pipelineBody: any[]) => {
    try {
      // 1. Get the connection and model
      const conn = await getDbConnection(database);
      const Model = getModel(conn, tableName);
      
      // 2. Process each pipeline stage to convert string ObjectIds to real ObjectIds
      const processedPipeline = pipelineBody.map(stage => {
        // Process each stage object
        const processedStage: any = {};
        for (const [key, value] of Object.entries(stage)) {
          processedStage[key] = convertStringsToObjectIdsAndDates(value, Model.schema);
        }
        return processedStage;
      });
      
      // 3. Run the aggregation directly with the processed pipeline
      const result = await Model.aggregate(processedPipeline);
      
      // 4. Return the raw result
      return {
        success: true,
        data: result
      };
    } catch (error: any) {
      if (error instanceof NotFoundError) {
        return { success: false, error: error.message, status: error.status };
      }
      return { 
        success: false, 
        error: error.message || "Failed to execute direct aggregation",
        stack: error.stack
      };
    }
  },

  // Business-specific analytics aggregations
  getBusinessAnalytics: async (database: string, dateRange?: { start: Date; end: Date }) => {
    try {
      const conn = await getDbConnection(database);
      const SalesModel = getModel(conn, "SaleRecords");
      
      // Build match condition based on date range
      const matchCondition: any = {};
      if (dateRange) {
        matchCondition.timestamp = {
          $gte: dateRange.start,
          $lte: dateRange.end
        };
      }
      
      const pipeline = [
        ...(Object.keys(matchCondition).length > 0 ? [{ $match: matchCondition }] : []),
        {
          $facet: {
            // Revenue by category
            revenueByCategory: [
              {
                $group: {
                  _id: '$category',
                  totalRevenue: { $sum: '$totalAmount' },
                  salesCount: { $sum: 1 },
                  itemsSold: { $sum: '$quantity' }
                }
              }
            ],
            // Top selling items
            topSellingItems: [
              {
                $group: {
                  _id: '$itemName',
                  totalQuantity: { $sum: '$quantity' },
                  totalRevenue: { $sum: '$totalAmount' },
                  salesCount: { $sum: 1 }
                }
              },
              { $sort: { totalQuantity: -1 } },
              { $limit: 10 }
            ],
            // Daily sales trends
            dailyTrends: [
              {
                $group: {
                  _id: {
                    year: { $year: '$timestamp' },
                    month: { $month: '$timestamp' },
                    day: { $dayOfMonth: '$timestamp' }
                  },
                  revenue: { $sum: '$totalAmount' },
                  sales: { $sum: 1 },
                  items: { $sum: '$quantity' }
                }
              },
              { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
            ],
            // Overall stats
            overallStats: [
              {
                $group: {
                  _id: null,
                  totalRevenue: { $sum: '$totalAmount' },
                  totalSales: { $sum: 1 },
                  totalItems: { $sum: '$quantity' },
                  avgSaleAmount: { $avg: '$totalAmount' }
                }
              }
            ]
          }
        }
      ];
      
      const [result] = await SalesModel.aggregate(pipeline as any);
      
      return {
        success: true,
        data: result
      };
    } catch (error: any) {
      return { 
        success: false, 
        error: error.message || "Failed to get business analytics"
      };
    }
  },

  // Cross-collection aggregation (e.g., join MenuItems with SaleRecords)
  crossCollectionAnalysis: async (database: string) => {
    try {
      const conn = await getDbConnection(database);
      const SalesModel = getModel(conn, "SaleRecords");
      
      const pipeline = [
        {
          $lookup: {
            from: 'menuitems',
            localField: 'menuItemId',
            foreignField: 'id',
            as: 'menuItemDetails'
          }
        },
        {
          $unwind: {
            path: '$menuItemDetails',
            preserveNullAndEmptyArrays: true
          }
        },
        {
          $group: {
            _id: {
              category: '$category',
              itemName: '$itemName'
            },
            totalRevenue: { $sum: '$totalAmount' },
            totalQuantity: { $sum: '$quantity' },
            salesCount: { $sum: 1 },
            avgPrice: { $avg: '$unitPrice' },
            isAvailable: { $first: '$menuItemDetails.isAvailable' }
          }
        },
        {
          $sort: { totalRevenue: -1 }
        }
      ];
      
      const result = await SalesModel.aggregate(pipeline as any);
      
      return {
        success: true,
        data: result
      };
    } catch (error: any) {
      return { 
        success: false, 
        error: error.message || "Failed to execute cross-collection analysis"
      };
    }
  }
};

export default searchService; 