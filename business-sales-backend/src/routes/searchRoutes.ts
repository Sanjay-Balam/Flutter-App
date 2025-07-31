import { Elysia, t } from 'elysia';
import searchService from '../services/SearchService';

export const searchRoutes = new Elysia({ prefix: '' })
  // POST /search/:database/:tableName - Advanced search with aggregation
  .post('/:database/searchresource/:tableName', async ({ params, body, query }) => {
    const { database, tableName } = params;
    const options = {
      page: query.page ? parseInt(query.page as string) : undefined,
      pageSize: query.pageSize ? parseInt(query.pageSize as string) : undefined
    };
    
    return await searchService.searchResource(database, tableName, body, options);
  }, {
    params: t.Object({
      database: t.String(),
      tableName: t.String()
    }),
    query: t.Optional(t.Object({
      page: t.Optional(t.String()),
      pageSize: t.Optional(t.String())
    })),
    body: t.Optional(t.Object({
      filter: t.Optional(t.Any()),
      sort: t.Optional(t.Any()),
      project: t.Optional(t.Any()),
      lookups: t.Optional(t.Array(t.Any())),
      unwind: t.Optional(t.Union([t.String(), t.Array(t.String())])),
      addFields: t.Optional(t.Any()),
      customStages: t.Optional(t.Array(t.Any()))
    }))
  })

  // GET /search/:database/:tableName/:id - Get single resource
  .get('/:database/searchresource/:tableName/:id', async ({ params }) => {
    const { database, tableName, id } = params;
    return await searchService.getResource(database, tableName, { id });
  }, {
    params: t.Object({
      database: t.String(),
      tableName: t.String(),
      id: t.String()
    })
  })

  // POST /search/:database/:tableName/create - Create new resource
  .post('/:database/createresource/:tableName', async ({ params, body }) => {
    const { database, tableName } = params;
    return await searchService.createResource(database, tableName, body);
  }, {
    params: t.Object({
      database: t.String(),
      tableName: t.String()
    }),
    body: t.Any()
  })

  // PUT /search/:database/:tableName/:id - Update resource
  .put('/:database/updateresource/:tableName/:id', async ({ params, body }) => {
    const { database, tableName, id } = params;
    return await searchService.updateResource(database, tableName, { id }, body);
  }, {
    params: t.Object({
      database: t.String(),
      tableName: t.String(),
      id: t.String()
    }),
    body: t.Any()
  })

  // DELETE /search/:database/:tableName/:id - Delete resource
  .delete('/:database/deleteresource/:tableName/:id', async ({ params }) => {
    const { database, tableName, id } = params;
    return await searchService.deleteResource(database, tableName, { id });
  }, {
    params: t.Object({
      database: t.String(),
      tableName: t.String(),
      id: t.String()
    })
  })

  // POST /search/:database/:tableName/aggregate - Direct aggregation
  .post('/:database/aggregatetable/:tableName', async ({ params, body }) => {
    const { database, tableName } = params;
    return await searchService.directAggregation(database, tableName, body);
  }, {
    params: t.Object({
      database: t.String(),
      tableName: t.String()
    }),
    body: t.Array(t.Any())
  })

  // PATCH /search/:database/:tableName/:id/remove-keys - Remove keys from document
  .patch('/:database/removekeys/:tableName/:id', async ({ params, body }) => {
    const { database, tableName, id } = params;
    return await searchService.removeKeysFromBody(database, tableName, { id }, body);
  }, {
    params: t.Object({
      database: t.String(),
      tableName: t.String(),
      id: t.String()
    }),
    body: t.Any()
  })

  // GET /search/:database/menu-item/:id - Get menu item by ID
  .get('/:database/getmenuitem/:id', async ({ params }) => {
    const { database, id } = params;
    return await searchService.getMenuItemById(database, id);
  }, {
    params: t.Object({
      database: t.String(),
      id: t.String()
    })
  })

  // GET /search/:database/sales-by-menu/:id - Get sales by menu item ID
  .get('/:database/getsalesbymenu/:id', async ({ params, query }) => {
    const { database, id } = params;
    const options = {
      page: query.page ? parseInt(query.page as string) : undefined,
      pageSize: query.pageSize ? parseInt(query.pageSize as string) : undefined
    };
    
    return await searchService.getSalesByMenuItemId(database, id, options);
  }, {
    params: t.Object({
      database: t.String(),
      id: t.String()
    }),
    query: t.Optional(t.Object({
      page: t.Optional(t.String()),
      pageSize: t.Optional(t.String())
    }))
  })

  // GET /search/:database/business-analytics - Get business analytics
  .get('/:database/getbusinessanalytics', async ({ params, query }) => {
    const { database } = params;
    
    let dateRange;
    if (query.startDate && query.endDate) {
      dateRange = {
        start: new Date(query.startDate as string),
        end: new Date(query.endDate as string)
      };
    }
    
    return await searchService.getBusinessAnalytics(database, dateRange);
  }, {
    params: t.Object({
      database: t.String()
    }),
    query: t.Optional(t.Object({
      startDate: t.Optional(t.String()),
      endDate: t.Optional(t.String())
    }))
  })

  // GET /search/:database/cross-collection-analysis - Cross-collection analysis
  .get('/:database/getcrosscollectionanalysis', async ({ params }) => {
    const { database } = params;
    return await searchService.crossCollectionAnalysis(database);
  }, {
    params: t.Object({
      database: t.String()
    })
  }); 