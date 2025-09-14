const mongoose = require('mongoose');
const Product = require('../src/models/Product').default;

const MONGODB_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/mern-stack-dev';

async function runRollback() {
  await mongoose.connect(MONGODB_URI);
  console.log('Starting rollback...');

  // This is a simple rollback. A real one might be more complex.
  // We will just remove the new priceV2 field.
  const result = await Product.updateMany(
    { priceV2: { $exists: true } },
    { $unset: { priceV2: "" } }
  );

  console.log(`Rollback completed. Removed 'priceV2' field from ${result.nModified} documents.`);
  await mongoose.disconnect();
}

runRollback().catch(console.error);
