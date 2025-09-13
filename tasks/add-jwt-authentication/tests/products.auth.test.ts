import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/index';
import Product from '../../../src/server/src/models/Product';
import User from '../../../src/server/src/models/User';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-prod-auth';

// Hooks for database connection
beforeAll(async () => {
  await mongoose.connect(MONGO_URI_TEST);
});

afterAll(async () => {
  await mongoose.connection.close();
});

beforeEach(async () => {
  await Product.deleteMany({});
  if (mongoose.models.User) {
    await User.deleteMany({});
  }
});

describe('Protected Product API', () => {
  const newProduct = {
    name: 'A Protected Product',
    description: 'This should only be creatable by authenticated users.',
    price: 19.99,
    category: 'Protected',
  };

  it('should return 401 Unauthorized when trying to create a product without a token', async () => {
    const res = await request(app)
      .post('/api/products')
      .send(newProduct);

    // On baseline, this will be 201. The task is to make it 401.
    expect(res.statusCode).toEqual(401);
  });

  it('should return 401 Unauthorized for an invalid or malformed token', async () => {
    const res = await request(app)
      .post('/api/products')
      .set('Authorization', 'Bearer aninvalidtoken')
      .send(newProduct);

    expect(res.statusCode).toEqual(401);
  });

  it('should allow product creation for a user with a valid token', async () => {
    // 1. Register a user
    const testUser = { email: 'authed@example.com', password: 'password123' };
    await request(app).post('/api/auth/register').send(testUser);

    // 2. Log in to get a token
    const loginRes = await request(app).post('/api/auth/login').send(testUser);
    const token = loginRes.body.token;
    expect(token).toBeDefined();

    // 3. Use the token to create a product
    const productRes = await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${token}`)
      .send(newProduct);

    expect(productRes.statusCode).toEqual(201);
    expect(productRes.body.name).toBe(newProduct.name);
  });
});
