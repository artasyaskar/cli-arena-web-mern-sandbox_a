// This is a standalone script to be run with Node.js
// node db/seed.js

const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env vars
dotenv.config({ path: './src/server/.env' }); // Assuming .env is in the server src

// --- IMPORTANT ---
// We need to define the Mongoose schema here because this script
// is run outside of the TypeScript application context.
const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true },
  category: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

const Product = mongoose.model('Product', ProductSchema);
// ---

const sampleProducts = [
  {
    name: 'Laptop Pro',
    description: 'A high-performance laptop for professionals.',
    price: 1499.99,
    category: 'Electronics',
  },
  {
    name: 'Wireless Mouse',
    description: 'Ergonomic wireless mouse with long battery life.',
    price: 49.99,
    category: 'Electronics',
  },
  {
    name: 'Mechanical Keyboard',
    description: 'RGB mechanical keyboard with tactile switches.',
    price: 129.99,
    category: 'Electronics',
  },
  {
    name: 'The Pragmatic Programmer',
    description: 'From journeyman to master, a classic book on software engineering.',
    price: 39.99,
    category: 'Books',
  },
  {
    name: 'Clean Code',
    description: 'A Handbook of Agile Software Craftsmanship by Robert C. Martin.',
    price: 34.99,
    category: 'Books',
  },
];

const seedDB = async () => {
  const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/mern-sandbox';

  try {
    await mongoose.connect(MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('MongoDB connected for seeding.');

    // Clear existing products
    await Product.deleteMany({});
    console.log('Products collection cleared.');

    // Insert new sample products
    await Product.insertMany(sampleProducts);
    console.log('Sample products inserted.');

    console.log('Database seeding completed successfully!');
  } catch (err) {
    console.error('Error during database seeding:', err);
    process.exit(1);
  } finally {
    mongoose.connection.close();
    console.log('MongoDB connection closed.');
  }
};

seedDB();
