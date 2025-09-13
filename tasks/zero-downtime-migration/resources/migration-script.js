const mongoose = require('mongoose');
const Product = require('../src/models/Product').default; // Adjust path as needed

const MONGODB_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/mern-stack-dev';

async function runMigration() {
  await mongoose.connect(MONGODB_URI);

  console.log('Starting migration...');

  const productsToMigrate = await Product.find({ price: { $exists: true, $type: 'number' } });

  console.log(`Found ${productsToMigrate.length} products to migrate.`);

  for (const product of productsToMigrate) {
    product.priceV2 = {
      amount: product.price,
      currency: 'USD',
    };
    // We are not unsetting the old price field here. That's a separate step.
    await product.save();
    console.log(`Migrated product ${product._id}`);
  }

  console.log('Migration completed.');
  await mongoose.disconnect();
}

runMigration().catch(console.error);
