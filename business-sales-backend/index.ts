import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { swagger } from '@elysiajs/swagger';
import Database from './src/config/database';
import { searchRoutes } from './src/routes/searchRoutes';
import invoiceRoutes from './src/routes/invoice.routes';

// Initialize database connection
await Database.connect();

const app = new Elysia()
  // Add CORS support
  .use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
  }))

  // Add Swagger documentation
  .use(swagger({
    documentation: {
      info: {
        title: 'Business Sales Tracker API',
        description: 'REST API for managing bakery menu items, sales, and analytics',
        version: '1.0.0'
      },
      tags: [
        {
          name: 'Search',
          description: 'Universal search and CRUD endpoints for all collections'
        },
        {
          name: 'Invoices',
          description: 'Invoice generation, management, and business settings endpoints'
        },
        {
          name: 'Business Analytics',
          description: 'Specialized business analytics and reporting endpoints'
        }
      ]
    }
  }))

  // Health check endpoint
  .get('/', () => ({
    success: true,
    message: 'Business Sales Tracker API is running!',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
          endpoints: {
        documentation: '/swagger',
        search: '/api/v1/search',
        invoices: '/api/{database}/generate-invoice/{saleId}',
        businessAnalytics: '/api/v1/search/{database}/business-analytics',
        menuItems: '/api/v1/search/{database}/MenuItems',
        salesRecords: '/api/v1/search/{database}/SaleRecords'
      }
  }))

  // Health check endpoint
  .get('/health', () => ({
    success: true,
    message: 'Server is healthy',
    database: Database.getConnectionStatus() ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  }))

  // API routes with versioning
  .group('', (app) => 
    app
      .use(searchRoutes)
      .use(invoiceRoutes)
  )

  // Global error handler
  .onError(({ code, error, set }) => {
    const errorMessage = error instanceof Error ? error.message : String(error);
    const errorStack = error instanceof Error ? error.stack : undefined;
    
    console.error('API Error:', { code, error: errorMessage, stack: errorStack });
    
    switch (code) {
      case 'VALIDATION':
        set.status = 400;
        return {
          success: false,
          message: 'Validation Error',
          error: errorMessage
        };
      
      case 'NOT_FOUND':
        set.status = 404;
        return {
          success: false,
          message: 'Endpoint not found',
          error: 'The requested resource was not found'
        };
      
      default:
        set.status = 500;
        return {
          success: false,
          message: 'Internal Server Error',
          error: process.env.NODE_ENV === 'development' ? errorMessage : 'Something went wrong'
        };
    }
  })

  // Handle 404 for all other routes
  .all('*', ({ set }) => {
    set.status = 404;
    return {
      success: false,
      message: 'Endpoint not found',
      error: 'The requested resource was not found'
    };
  });

const port = parseInt(process.env.PORT || '3000');

app.listen(port, () => {
  console.log(`🚀 Business Sales Tracker API is running on port ${port}`);
  console.log(`📚 API Documentation available at /swagger`);
  console.log(`🏥 Health check available at /health`);
  console.log(`📊 Database status: ${Database.getConnectionStatus() ? '✅ Connected' : '❌ Disconnected'}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('⏳ Shutting down gracefully...');
  await Database.disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('⏳ Shutting down gracefully...');
  await Database.disconnect();
  process.exit(0);
});