import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/app';
import Product from '../../../src/server/src/models/Product';
import Purchase from '../../../src/server/src/models/Purchase';
import User from '../../../src/server/src/models/User';
import { connectDB, disconnectDB } from '../../../src/server/src/config/database';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-aggregation';

let userToken: string;
let userId: string;
let product1Id: string;
let product2Id: string;

beforeAll(async () => {
  await connectDB(MONGO_URI_TEST);

  // Clean up
  await User.deleteMany({});
  await Product.deleteMany({});
  await Purchase.deleteMany({});

  // Create user directly
  const user = await new User({ email: 'agg@test.com', password: 'password123' }).save() as any;
  userId = user._id.toString();
  userToken = 'dummy-token'; // Not used in the test

  // Create products
  const p1 = await new Product({ name: 'Product A', description: 'desc', price: 10, category: 'cat' }).save() as any;
  product1Id = p1._id.toString();
  const p2 = await new Product({ name: 'Product B', description: 'desc', price: 20, category: 'cat' }).save() as any;
  product2Id = p2._id.toString();

  // Create purchases
  // Product A is purchased 3 times
  await new Purchase({ userId, productId: product1Id }).save();
  await new Purchase({ userId, productId: product1Id }).save();
  await new Purchase({ userId, productId: product1Id }).save();
  // Product B is purchased 1 time
  await new Purchase({ userId, productId: product2Id }).save();
});

afterAll(async () => {
  await disconnectDB();
});

describe('GET /api/products (Aggregation Performance)', () => {
  it('should return all products, each with a correct purchaseCount field', async () => {
    const res = await request(app)
      .get('/api/products');

    expect(res.statusCode).toEqual(200);
    expect(res.body).toBeInstanceOf(Array);
    expect(res.body.length).toBe(2);

    interface ProductResponse {
      _id: string;
      name: string;
      price: number;
      purchaseCount: number;
    }

    const productA = res.body.find((p: ProductResponse) => p.name === 'Product A');
    const productB = res.body.find((p: ProductResponse) => p.name === 'Product B');

    expect(productA).toBeDefined();
    expect(productB).toBeDefined();

    expect(productA.purchaseCount).toBe(3);
    expect(productB.purchaseCount).toBe(1);
  });

  it('should execute the query in a performant way (under 100ms)', async () => {
    // The inefficient N+1 query will be slow, especially with more data.
    // This test measures the execution time and will fail if it's too slow.
    const startTime = Date.now();

    await request(app)
      .get('/api/products');

    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log(`Query duration: ${duration}ms`);
    expect(duration).toBeLessThan(100);
  });
});
