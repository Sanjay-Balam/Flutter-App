import Database from './src/config/database';
import mongoose from 'mongoose';

async function verifyCollections() {
  try {
    await Database.connect();
    const db = mongoose.connection.db!;
    
    const collections = await db.listCollections().toArray();
    
    console.log('\n✅ Collections in DemoDB:');
    collections.forEach(col => console.log(`  ✓ ${col.name}`));
    console.log(`\n📊 Total: ${collections.length} collections\n`);
    
    await Database.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

verifyCollections();

