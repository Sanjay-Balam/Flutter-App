import searchService from '../services/SearchService';

// Menu data that matches your Flutter app
const menuItems = [
  // Milk Cakes - All 99/-
  {
    id: 'milk_malai',
    name: 'Milk Malai',
    category: 'Milk Cakes',
    prices: { 'Regular': 99 },
    description: 'Creamy milk-based cake with malai flavor',
    isAvailable: true
  },
  {
    id: 'oreo_milk',
    name: 'Oreo',
    category: 'Milk Cakes',
    prices: { 'Regular': 99 },
    description: 'Milk cake with Oreo cookie flavor',
    isAvailable: true
  },
  {
    id: 'biscoff_milk',
    name: 'Biscoff',
    category: 'Milk Cakes',
    prices: { 'Regular': 99 },
    description: 'Milk cake with Biscoff cookie flavor',
    isAvailable: true
  },
  {
    id: 'dairy_milk',
    name: 'Dairy Milk',
    category: 'Milk Cakes',
    prices: { 'Regular': 99 },
    description: 'Chocolate milk cake with Dairy Milk flavor',
    isAvailable: true
  },
  {
    id: 'ras_malai',
    name: 'Ras Malai',
    category: 'Milk Cakes',
    prices: { 'Regular': 99 },
    description: 'Traditional Ras Malai flavored milk cake',
    isAvailable: true
  },

  // Cheese Cakes - Small 79/-, Large 139/-
  {
    id: 'lotus_biscoff_cheese',
    name: 'Lotus Biscoff',
    category: 'Cheese Cakes',
    prices: {
      'Small': 79,
      'Large': 139
    },
    description: 'Rich cheesecake with Lotus Biscoff flavor',
    isAvailable: true
  },
  {
    id: 'oreo_cheese',
    name: 'Oreo',
    category: 'Cheese Cakes',
    prices: {
      'Small': 79,
      'Large': 139
    },
    description: 'Cheesecake with crushed Oreo cookies',
    isAvailable: true
  },
  {
    id: 'blueberry_cheese',
    name: 'Blueberry',
    category: 'Cheese Cakes',
    prices: {
      'Small': 79,
      'Large': 139
    },
    description: 'Fresh blueberry cheesecake',
    isAvailable: true
  },

  // Chocolate Brownie - 149/-
  {
    id: 'chocolate_brownie',
    name: 'Chocolate Brownie',
    category: 'Chocolate Brownie',
    prices: { 'Regular': 149 },
    description: 'Rich and fudgy chocolate goodness topped with a scoop of vanilla ice cream. The perfect dessert for chocolate lovers.',
    isAvailable: true
  }
];

export async function seedMenuItems() {
  try {
    const database = process.env.MONGODB_DB_NAME || 'business-sales-db';
    
    console.log('🌱 Starting to seed menu items using SearchService...');

    // Clear existing menu items using search service
    try {
      const existingItems = await searchService.searchResource(database, 'MenuItems', {
        filter: {},
        project: { id: 1 }
      });
      
      if (existingItems.success && existingItems.data && existingItems.data.length > 0) {
        console.log(`🗑️ Found ${existingItems.data.length} existing menu items, clearing them...`);
        
        for (const item of existingItems.data) {
          await searchService.deleteResource(database, 'MenuItems', { id: item.id });
        }
        console.log('✅ Cleared existing menu items');
      }
    } catch (error) {
      console.log('ℹ️ No existing menu items found or error clearing them');
    }

    // Insert new menu items using search service
    const insertedItems = [];
    for (const menuItem of menuItems) {
      try {
        const result = await searchService.createResource(database, 'MenuItems', menuItem);
        if (result.success) {
          insertedItems.push(result.data);
        } else {
          console.error(`❌ Failed to create menu item ${menuItem.name}:`, result.error);
        }
      } catch (error) {
        console.error(`❌ Error creating menu item ${menuItem.name}:`, error);
      }
    }

    console.log(`✅ Successfully seeded ${insertedItems.length} menu items:`);

    // Group by category for better display
    const groupedItems = insertedItems.reduce((acc, item) => {
      if (!acc[item.category]) {
        acc[item.category] = [];
      }
      acc[item.category].push(item);
      return acc;
    }, {} as Record<string, any[]>);

    Object.entries(groupedItems).forEach(([category, items]) => {
      console.log(`\n📂 ${category.toUpperCase()}:`);
      items.forEach((item: any) => {
        const pricesStr = Object.entries(item.prices).map(([size, price]) => `${size}: ₹${price}`).join(', ');
        console.log(`   • ${item.name} (${pricesStr})`);
      });
    });

    console.log('\n🎉 Menu items seeding completed successfully!');
    
    // Test the search functionality
    console.log('\n🔍 Testing search functionality...');
    const searchResult = await searchService.searchResource(database, 'MenuItems', {
      filter: { category: 'Milk Cakes' },
      sort: { name: 1 }
    });
    
    if (searchResult.success) {
      console.log(`✅ Search test successful! Found ${searchResult.data.length} milk cakes`);
    } else {
      console.log('⚠️ Search test failed:', searchResult.error);
    }

    return insertedItems;

  } catch (error) {
    console.error('❌ Error seeding menu items:', error);
    throw error;
  }
}

// Sample sales data seeder
export async function seedSampleSales() {
  try {
    const database = process.env.MONGODB_DB_NAME || 'business-sales-db';
    
    console.log('🌱 Starting to seed sample sales data...');

    // Get menu items first
    const menuItemsResult = await searchService.searchResource(database, 'MenuItems', {
      filter: {},
      project: { id: 1, name: 1, category: 1, prices: 1 }
    });

    if (!menuItemsResult.success || !menuItemsResult.data.length) {
      console.log('❌ No menu items found. Please seed menu items first.');
      return;
    }

    const menuItems = menuItemsResult.data;
    const sampleSales = [];

    // Generate 20 sample sales over the last 7 days
    const today = new Date();
    for (let i = 0; i < 20; i++) {
      const randomMenuItem = menuItems[Math.floor(Math.random() * menuItems.length)];
      const availableSizes = Object.keys(randomMenuItem.prices);
      const randomSize = availableSizes[Math.floor(Math.random() * availableSizes.length)];
      const unitPrice = randomMenuItem.prices[randomSize];
      const quantity = Math.floor(Math.random() * 3) + 1; // 1-3 items
      
      // Random timestamp within last 7 days
      const daysAgo = Math.floor(Math.random() * 7);
      const hoursAgo = Math.floor(Math.random() * 24);
      const timestamp = new Date(today.getTime() - (daysAgo * 24 * 60 * 60 * 1000) - (hoursAgo * 60 * 60 * 1000));

      const saleData = {
        id: `sale_${Date.now()}_${i}`,
        menuItemId: randomMenuItem.id,
        itemName: randomMenuItem.name,
        category: randomMenuItem.category,
        size: randomSize,
        unitPrice: unitPrice,
        quantity: quantity,
        totalAmount: unitPrice * quantity,
        timestamp: timestamp,
        notes: Math.random() > 0.7 ? 'Customer requested extra packaging' : undefined
      };

      const result = await searchService.createResource(database, 'SaleRecords', saleData);
      if (result.success) {
        sampleSales.push(result.data);
      }
    }

    console.log(`✅ Successfully seeded ${sampleSales.length} sample sales`);
    
    // Test analytics
    console.log('\n📊 Testing business analytics...');
    const analyticsResult = await searchService.getBusinessAnalytics(database);
    
    if (analyticsResult.success) {
      const analytics = analyticsResult.data;
      console.log('✅ Analytics test successful!');
      console.log(`   • Total Revenue: ₹${analytics.overallStats[0]?.totalRevenue || 0}`);
      console.log(`   • Total Sales: ${analytics.overallStats[0]?.totalSales || 0}`);
      console.log(`   • Categories: ${analytics.revenueByCategory.length}`);
      console.log(`   • Top Items: ${analytics.topSellingItems.length}`);
    }

    return sampleSales;

  } catch (error) {
    console.error('❌ Error seeding sample sales:', error);
    throw error;
  }
}

// Run seeder if this file is executed directly
if (import.meta.main) {
  console.log('🚀 Starting data seeding process...');
  
  try {
    await seedMenuItems();
    await seedSampleSales();
    console.log('\n🎉 All seeding completed successfully!');
  } catch (error) {
    console.error('❌ Seeding failed:', error);
  }
  
  process.exit(0);
}