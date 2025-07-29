import searchService from '../services/SearchService';
import { MenuCategory, ItemSize, UserRole } from '../types';

// Sample users for testing
const sampleUsers = [
  {
    id: 'user_owner_001',
    firstName: 'Sanjay',
    lastName: 'Balam',
    email: 'sanjay@bakery.com',
    phone: '+91-9876543210',
    password: 'securepass123',
    role: UserRole.OWNER,
    businessName: 'Sweet Dreams Bakery',
    businessType: 'bakery',
    isActive: true,
    address: {
      street: '123 Baker Street',
      city: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
      zipCode: '400001'
    },
    preferences: {
      currency: 'INR',
      timezone: 'Asia/Kolkata',
      notifications: {
        email: true,
        push: true,
        sms: false
      }
    }
  },
  {
    id: 'user_manager_001',
    firstName: 'Priya',
    lastName: 'Sharma',
    email: 'priya@bakery.com',
    phone: '+91-9876543211',
    password: 'managerpass123',
    role: UserRole.MANAGER,
    businessName: 'Sweet Dreams Bakery',
    businessType: 'bakery',
    isActive: true,
    address: {
      street: '456 Manager Lane',
      city: 'Mumbai',
      state: 'Maharashtra',
      country: 'India',
      zipCode: '400002'
    }
  }
];

// Menu data linked to users
const getMenuItemsForUser = (userId: string) => [
  // Milk Cakes - All 99/-
  {
    id: 'milk_malai',
    name: 'Milk Malai',
    category: MenuCategory.MILK_CAKES,
    prices: { [ItemSize.REGULAR]: 99 },
    description: 'Creamy milk-based cake with malai flavor',
    isAvailable: true,
    userId
  },
  {
    id: 'oreo_milk',
    name: 'Oreo',
    category: MenuCategory.MILK_CAKES,
    prices: { [ItemSize.REGULAR]: 99 },
    description: 'Milk cake with Oreo cookie flavor',
    isAvailable: true,
    userId
  },
  {
    id: 'biscoff_milk',
    name: 'Biscoff',
    category: MenuCategory.MILK_CAKES,
    prices: { [ItemSize.REGULAR]: 99 },
    description: 'Milk cake with Biscoff cookie flavor',
    isAvailable: true,
    userId
  },
  {
    id: 'dairy_milk',
    name: 'Dairy Milk',
    category: MenuCategory.MILK_CAKES,
    prices: { [ItemSize.REGULAR]: 99 },
    description: 'Chocolate milk cake with Dairy Milk flavor',
    isAvailable: true,
    userId
  },
  {
    id: 'ras_malai',
    name: 'Ras Malai',
    category: MenuCategory.MILK_CAKES,
    prices: { [ItemSize.REGULAR]: 99 },
    description: 'Traditional Ras Malai flavored milk cake',
    isAvailable: true,
    userId
  },

  // Cheese Cakes - Small 79/-, Large 139/-
  {
    id: 'lotus_biscoff_cheese',
    name: 'Lotus Biscoff',
    category: MenuCategory.CHEESE_CAKES,
    prices: {
      [ItemSize.SMALL]: 79,
      [ItemSize.LARGE]: 139
    },
    description: 'Rich cheesecake with Lotus Biscoff flavor',
    isAvailable: true,
    userId
  },
  {
    id: 'oreo_cheese',
    name: 'Oreo',
    category: MenuCategory.CHEESE_CAKES,
    prices: {
      [ItemSize.SMALL]: 79,
      [ItemSize.LARGE]: 139
    },
    description: 'Cheesecake with crushed Oreo cookies',
    isAvailable: true,
    userId
  },
  {
    id: 'blueberry_cheese',
    name: 'Blueberry',
    category: MenuCategory.CHEESE_CAKES,
    prices: {
      [ItemSize.SMALL]: 79,
      [ItemSize.LARGE]: 139
    },
    description: 'Fresh blueberry cheesecake',
    isAvailable: true,
    userId
  },

  // Chocolate Brownie - 149/-
  {
    id: 'chocolate_brownie',
    name: 'Chocolate Brownie',
    category: MenuCategory.CHOCOLATE_BROWNIE,
    prices: { [ItemSize.REGULAR]: 149 },
    description: 'Rich and fudgy chocolate goodness topped with a scoop of vanilla ice cream. The perfect dessert for chocolate lovers.',
    isAvailable: true,
    userId
  }
];

export async function seedUsersAndData() {
  try {
    const database = process.env.MONGODB_DB_NAME || 'business-sales-db';
    
    console.log('🚀 Starting comprehensive data seeding with users...');

    // Step 1: Clear existing data
    console.log('🗑️ Clearing existing data...');
    try {
      await clearExistingData(database);
    } catch (error) {
      console.log('ℹ️ No existing data found or error clearing data');
    }

    // Step 2: Create Users
    console.log('👥 Creating users...');
    const createdUsers = [];
    for (const user of sampleUsers) {
      try {
        const result = await searchService.createResource(database, 'Users', user);
        if (result.success) {
          createdUsers.push(result.data);
          console.log(`   ✅ Created user: ${user.firstName} ${user.lastName} (${user.role})`);
        } else {
          console.error(`   ❌ Failed to create user ${user.firstName}:`, result.error);
        }
      } catch (error) {
        console.error(`   ❌ Error creating user ${user.firstName}:`, error);
      }
    }

    if (createdUsers.length === 0) {
      console.error('❌ No users created. Cannot proceed with menu items and sales.');
      return;
    }

    // Step 3: Create Menu Items for the first user (owner)
    const ownerUser = createdUsers.find(user => user.role === 'owner') || createdUsers[0];
    console.log(`🍰 Creating menu items for user: ${ownerUser.firstName} ${ownerUser.lastName}...`);
    
    const menuItems = getMenuItemsForUser(ownerUser.id);
    const createdMenuItems = [];
    
    for (const menuItem of menuItems) {
      try {
        const result = await searchService.createResource(database, 'MenuItems', menuItem);
        if (result.success) {
          createdMenuItems.push(result.data);
        } else {
          console.error(`   ❌ Failed to create menu item ${menuItem.name}:`, result.error);
        }
      } catch (error) {
        console.error(`   ❌ Error creating menu item ${menuItem.name}:`, error);
      }
    }

    console.log(`✅ Successfully created ${createdMenuItems.length} menu items`);

    // Group by category for display
    const groupedItems = createdMenuItems.reduce((acc, item) => {
      if (!acc[item.category]) {
        acc[item.category] = [];
      }
      acc[item.category].push(item);
      return acc;
    }, {} as Record<string, any[]>);

    Object.entries(groupedItems).forEach(([category, items]) => {
      console.log(`\n📂 ${category.toUpperCase()}:`);
      items.forEach(item => {
        const pricesStr = Object.entries(item.prices).map(([size, price]) => `${size}: ₹${price}`).join(', ');
        console.log(`   • ${item.name} (${pricesStr}) - User: ${ownerUser.firstName}`);
      });
    });

    // Step 4: Create Sample Sales linked to users
    console.log('\n💰 Creating sample sales for multiple users...');
    const sampleSales = [];

    // Generate sales for both users
    for (const user of createdUsers) {
      const userSalesCount = user.role === 'owner' ? 15 : 5; // More sales for owner
      
      for (let i = 0; i < userSalesCount; i++) {
        const randomMenuItem = createdMenuItems[Math.floor(Math.random() * createdMenuItems.length)];
        const availableSizes = Object.keys(randomMenuItem.prices);
        const randomSize = availableSizes[Math.floor(Math.random() * availableSizes.length)];
        const unitPrice = randomMenuItem.prices[randomSize];
        const quantity = Math.floor(Math.random() * 3) + 1; // 1-3 items
        
        // Random timestamp within last 14 days
        const daysAgo = Math.floor(Math.random() * 14);
        const hoursAgo = Math.floor(Math.random() * 24);
        const timestamp = new Date(Date.now() - (daysAgo * 24 * 60 * 60 * 1000) - (hoursAgo * 60 * 60 * 1000));

        const saleData = {
          id: `sale_${user.id}_${Date.now()}_${i}`,
          menuItemId: randomMenuItem.id,
          itemName: randomMenuItem.name,
          category: randomMenuItem.category,
          size: randomSize,
          unitPrice: unitPrice,
          quantity: quantity,
          totalAmount: unitPrice * quantity,
          timestamp: timestamp,
          notes: Math.random() > 0.8 ? `Sale by ${user.firstName} - Customer requested extra packaging` : undefined,
          userId: user.id
        };

        const result = await searchService.createResource(database, 'SaleRecords', saleData);
        if (result.success) {
          sampleSales.push(result.data);
        }
      }
    }

    console.log(`✅ Successfully created ${sampleSales.length} sample sales across ${createdUsers.length} users`);

    // Step 5: Test Analytics with User Context
    console.log('\n📊 Testing business analytics with user context...');
    const analyticsResult = await searchService.getBusinessAnalytics(database);
    
    if (analyticsResult.success) {
      const analytics = analyticsResult.data;
      console.log('✅ Analytics test successful!');
      console.log(`   • Total Revenue: ₹${analytics.overallStats[0]?.totalRevenue || 0}`);
      console.log(`   • Total Sales: ${analytics.overallStats[0]?.totalSales || 0}`);
      console.log(`   • Categories: ${analytics.revenueByCategory.length}`);
      console.log(`   • Top Items: ${analytics.topSellingItems.length}`);
      console.log(`   • Users Created: ${createdUsers.length}`);
    }

    // Step 6: Test User-specific queries
    console.log('\n🔍 Testing user-specific queries...');
    
    // Get sales by specific user
    const ownerSalesResult = await searchService.searchResource(database, 'SaleRecords', {
      filter: { userId: ownerUser.id },
      sort: { timestamp: -1 }
    });
    
    if (ownerSalesResult.success) {
      console.log(`✅ Found ${ownerSalesResult.data.length} sales for user: ${ownerUser.firstName} ${ownerUser.lastName}`);
    }

    // Get menu items by specific user
    const ownerMenuResult = await searchService.searchResource(database, 'MenuItems', {
      filter: { userId: ownerUser.id },
      sort: { name: 1 }
    });
    
    if (ownerMenuResult.success) {
      console.log(`✅ Found ${ownerMenuResult.data.length} menu items for user: ${ownerUser.firstName} ${ownerUser.lastName}`);
    }

    console.log('\n🎉 Comprehensive seeding with user relationships completed successfully!');
    
    return {
      users: createdUsers,
      menuItems: createdMenuItems,
      sales: sampleSales
    };

  } catch (error) {
    console.error('❌ Error in comprehensive seeding:', error);
    throw error;
  }
}

async function clearExistingData(database: string) {
  const collections = ['Users', 'MenuItems', 'SaleRecords'];
  
  for (const collection of collections) {
    try {
      const existingData = await searchService.searchResource(database, collection, {
        filter: {},
        project: { id: 1 }
      });
      
      if (existingData.success && existingData.data && existingData.data.length > 0) {
        console.log(`   🗑️ Found ${existingData.data.length} existing ${collection}, clearing...`);
        
        for (const item of existingData.data) {
          await searchService.deleteResource(database, collection, { id: item.id });
        }
        console.log(`   ✅ Cleared ${collection}`);
      }
    } catch (error) {
      console.log(`   ℹ️ No existing ${collection} found or error clearing them`);
    }
  }
}

// Run seeder if this file is executed directly
if (import.meta.main) {
  console.log('🎯 Starting comprehensive data seeding with user relationships...');
  
  try {
    await seedUsersAndData();
    console.log('\n🏆 All seeding completed successfully!');
  } catch (error) {
    console.error('💥 Seeding failed:', error);
  }
  
  process.exit(0);
} 