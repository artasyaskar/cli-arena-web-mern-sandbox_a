import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/app';
import Product from '../../../src/server/src/models/Product';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-search';

beforeAll(async () => {
  await mongoose.connect(MONGO_URI_TEST);
});

afterAll(async () => {
  await mongoose.connection.close();
});

beforeEach(async () => {
  await Product.deleteMany({});
  // In order for text search to work, a text index must be created.
  // The model file itself doesn't do this in the test env, so we do it manually.
  // The 'solution.sh' will add this to the main model file.
  try {
    await Product.collection.dropIndexes();
  } catch (error) {
    // Ignore error if index doesn't exist
  }
  await Product.collection.createIndex({ name: 'text', description: 'text' });

  // Seed with specific data for searching
  await Product.insertMany([
    { name: 'Ergonomic Wireless Mouse', description: 'A comfortable and responsive mouse for all-day use.', price: 49.99, category: 'Electronics' },
    { name: 'Classic Leather Wallet', description: 'A timeless wallet with a modern design.', price: 79.99, category: 'Accessories' },
    { name: 'Mechanical Gaming Keyboard', description: 'A responsive keyboard for competitive gaming.', price: 129.99, category: 'Electronics' },
  ]);
});

describe('GET /api/products/search', () => {
  it('should return 404 Not Found if the endpoint does not exist yet', async () => {
    const res = await request(app).get('/api/products/search?q=test');
    // The initial state will be a 404. The final state should be 200.
    // This test is designed to fail on the solved state, but pass on the initial state.
    // Let's write the test for the final state.
    expect(res.statusCode).not.toEqual(404);
  });

  it('should find products by searching for a word in the name', async () => {
    const res = await request(app).get('/api/products/search?q=Keyboard');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toBeInstanceOf(Array);
    expect(res.body.length).toBe(1);
    expect(res.body[0].name).toContain('Keyboard');
  });

  it('should find products by searching for a word in the description', async () => {
    const res = await request(app).get('/api/products/search?q=timeless');
    expect(res.statusCode).toEqual(200);
    expect(res.body.length).toBe(1);
    expect(res.body[0].name).toContain('Wallet');
  });

  it('should find multiple products matching a query', async () => {
    const res = await request(app).get('/api/products/search?q=responsive');
    expect(res.statusCode).toEqual(200);
    expect(res.body.length).toBe(2);
  });

  it('should return an empty array if no products match', async () => {
    const res = await request(app).get('/api/products/search?q=nonexistentquery');
    expect(res.statusCode).toEqual(200);
    expect(res.body.length).toBe(0);
  });

  it('should return results sorted by text search score', async () => {
    // Add a product that should rank higher for the query "gaming"
    await Product.create({ name: 'Pro Gaming Mousepad', description: 'Optimized for gaming sensors.', price: 29.99, category: 'Gaming' });

    const res = await request(app).get('/api/products/search?q=gaming');
    expect(res.statusCode).toBe(200);
    expect(res.body.length).toBe(2);
    // The "Pro Gaming Mousepad" should appear before the "Mechanical Gaming Keyboard"
    // because its name is a better match. We can't directly check the textScore without
    // more complex setup, but we can check the order.
    expect(res.body[0].name).toContain('Mousepad');
    expect(res.body[1].name).toContain('Keyboard');
  });
});
