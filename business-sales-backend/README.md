# Business Sales Tracker Backend

A powerful **Elysia.js** backend service with **MongoDB** for managing business sales, menu items, and analytics. Built with TypeScript and designed for the Flutter business sales tracking application.

## 🚀 Features

- **Universal Search Service**: Advanced MongoDB queries with aggregation pipelines
- **Menu Management**: CRUD operations for bakery menu items
- **Sales Tracking**: Record and manage sales transactions
- **Business Analytics**: Revenue insights, trends, and performance metrics
- **Cross-Collection Analysis**: Advanced reporting across multiple data collections
- **RESTful API**: Clean, documented endpoints with Swagger
- **Type Safety**: Full TypeScript support with comprehensive type definitions
- **Database Flexibility**: Multi-database support with connection caching

## 🛠️ Tech Stack

- **Runtime**: Bun (Fast JavaScript runtime)
- **Framework**: Elysia.js (Lightning-fast web framework)
- **Database**: MongoDB with Mongoose ODM
- **Language**: TypeScript
- **Documentation**: Swagger/OpenAPI
- **Validation**: Elysia's built-in validation with TypeBox

## 📋 Prerequisites

- **Bun** >= 1.0.0
- **MongoDB** >= 5.0
- **Node.js** >= 18 (for compatibility)

## 🏁 Quick Start

### 1. Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd business-sales-backend

# Install dependencies
bun install
```

### 2. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit the .env file with your configuration
```

### 3. Database Setup

Make sure MongoDB is running locally or update the `MONGODB_URI` in your `.env` file:

```env
MONGODB_URI=mongodb://localhost:27017/business-sales-db
MONGODB_DB_NAME=business-sales-db
PORT=3000
NODE_ENV=development
```

### 4. Seed Initial Data

```bash
# Seed menu items and sample sales
bun run src/utils/seedData.ts
```

### 5. Start the Server

```bash
# Development mode
bun run index.ts

# The server will start on http://localhost:3000
```

## 📚 API Documentation

Once the server is running, visit:

- **API Documentation**: http://localhost:3000/swagger
- **Health Check**: http://localhost:3000/health
- **Root Endpoint**: http://localhost:3000

## 🗃️ Data Models

### Menu Item
```typescript
{
  id: string;
  name: string;
  category: 'milkCakes' | 'cheeseCakes' | 'chocolateBrownie';
  prices: { [size: string]: number };
  description?: string;
  isAvailable: boolean;
}
```

### Sale Record
```typescript
{
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
}
```

## 🔍 Search Service API

The core of this backend is the powerful SearchService that provides:

### Basic CRUD Operations

```bash
# Create a menu item
POST /api/v1/search/business-sales-db/MenuItems/create
{
  "name": "Chocolate Cake",
  "category": "milkCakes",
  "prices": { "regular": 99 },
  "description": "Delicious chocolate cake"
}

# Get all menu items
POST /api/v1/search/business-sales-db/MenuItems
{
  "filter": {},
  "sort": { "name": 1 }
}

# Get single item
GET /api/v1/search/business-sales-db/MenuItems/milk_malai

# Update item
PUT /api/v1/search/business-sales-db/MenuItems/milk_malai
{
  "isAvailable": false
}

# Delete item
DELETE /api/v1/search/business-sales-db/MenuItems/milk_malai
```

### Advanced Search with Aggregation

```bash
# Search with filters and pagination
POST /api/v1/search/business-sales-db/SaleRecords?page=1&pageSize=10
{
  "filter": {
    "category": "milkCakes",
    "timestamp": {
      "$gte": "2024-01-01T00:00:00.000Z",
      "$lte": "2024-12-31T23:59:59.999Z"
    }
  },
  "sort": { "timestamp": -1 },
  "project": {
    "itemName": 1,
    "totalAmount": 1,
    "timestamp": 1
  }
}
```

### Business Analytics

```bash
# Get comprehensive business analytics
GET /api/v1/search/business-sales-db/business-analytics

# Get analytics for date range
GET /api/v1/search/business-sales-db/business-analytics?startDate=2024-01-01&endDate=2024-01-31

# Cross-collection analysis
GET /api/v1/search/business-sales-db/cross-collection-analysis
```

### Direct Aggregation Pipeline

```bash
# Execute custom MongoDB aggregation
POST /api/v1/search/business-sales-db/SaleRecords/aggregate
[
  {
    "$match": { "category": "cheeseCakes" }
  },
  {
    "$group": {
      "_id": "$itemName",
      "totalRevenue": { "$sum": "$totalAmount" },
      "count": { "$sum": 1 }
    }
  },
  {
    "$sort": { "totalRevenue": -1 }
  }
]
```

## 🏗️ Project Structure

```
business-sales-backend/
├── src/
│   ├── config/
│   │   └── database.ts          # Database configuration
│   ├── models/
│   │   ├── MenuItem.ts          # Menu item schema
│   │   └── SaleRecord.ts        # Sale record schema
│   ├── services/
│   │   └── SearchService.ts     # Core search service
│   ├── routes/
│   │   └── searchRoutes.ts      # API routes
│   ├── types/
│   │   └── index.ts             # TypeScript definitions
│   └── utils/
│       └── seedData.ts          # Database seeding utilities
├── index.ts                     # Main server file
├── package.json
├── .env.example
└── README.md
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/business-sales-db` |
| `MONGODB_DB_NAME` | Database name | `business-sales-db` |
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment mode | `development` |
| `CORS_ORIGIN` | CORS allowed origins | `*` |

## 📊 Sample Queries

### Get Today's Sales
```javascript
{
  "filter": {
    "timestamp": {
      "$gte": "2024-01-15T00:00:00.000Z",
      "$lte": "2024-01-15T23:59:59.999Z"
    }
  },
  "sort": { "timestamp": -1 }
}
```

### Top Selling Items
```javascript
[
  {
    "$group": {
      "_id": "$itemName",
      "totalQuantity": { "$sum": "$quantity" },
      "totalRevenue": { "$sum": "$totalAmount" }
    }
  },
  {
    "$sort": { "totalQuantity": -1 }
  },
  {
    "$limit": 5
  }
]
```

### Revenue by Category
```javascript
[
  {
    "$group": {
      "_id": "$category",
      "totalRevenue": { "$sum": "$totalAmount" },
      "salesCount": { "$sum": 1 }
    }
  }
]
```

## 🧪 Testing

```bash
# Run the seeder to populate test data
bun run src/utils/seedData.ts

# Test API endpoints using curl or Postman
curl http://localhost:3000/health
```

## 🚀 Deployment

### Production Environment

1. Set production environment variables
2. Ensure MongoDB is accessible
3. Build and run:

```bash
# Set production environment
export NODE_ENV=production

# Start the server
bun run index.ts
```

### Docker Deployment (Optional)

```dockerfile
FROM oven/bun:1
WORKDIR /app
COPY package.json bun.lockb ./
RUN bun install
COPY . .
EXPOSE 3000
CMD ["bun", "run", "index.ts"]
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

---

## 🔗 Related Projects

- **Flutter Frontend**: [Business Sales Tracker Mobile App]
- **MongoDB**: Database for persistent storage
- **Elysia.js**: Web framework for high-performance APIs
