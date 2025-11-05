import Database from './src/config/database';
import User from './src/models/User.schema';

async function fixUsersIndex() {
  try {
    await Database.connect();
    console.log('Connected to database');
    
    // Drop the problematic id_1 index from Users collection
    try {
      await User.collection.dropIndex('id_1');
      console.log('✅ Successfully dropped id_1 index from Users collection');
    } catch (e: any) {
      if (e.code === 27) {
        console.log('✅ Index id_1 does not exist (already removed)');
      } else {
        console.log('Note:', e.message);
      }
    }
    
    await Database.disconnect();
    console.log('✅ Done!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixUsersIndex();

