import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/index';
import User from '../../../src/server/src/models/User';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-security';

let adminToken: string;

beforeAll(async () => {
  await mongoose.connect(MONGO_URI_TEST);
  await User.deleteMany({});

  // Register and login an admin user to get a token for protected routes
  await request(app).post('/api/auth/register').send({ email: 'adminsec@example.com', password: 'password123', role: 'admin' });
  const loginRes = await request(app).post('/api/auth/login').send({ email: 'adminsec@example.com', password: 'password123' });
  adminToken = loginRes.body.token;
});

afterAll(async () => {
  await mongoose.connection.close();
});

describe('API Security Enhancements', () => {

  describe('Helmet Security Headers', () => {
    it('should not include the X-Powered-By header', async () => {
      const res = await request(app).get('/api/health');
      expect(res.headers['x-powered-by']).toBeUndefined();
    });

    it('should include the X-Content-Type-Options header with value "nosniff"', async () => {
        const res = await request(app).get('/api/health');
        expect(res.headers['x-content-type-options']).toEqual('nosniff');
    });
  });

  describe('Rate Limiting', () => {
    it('should return 429 Too Many Requests after exceeding the limit on the login route', async () => {
      const loginCredentials = { email: 'ratelimit@example.com', password: 'password' };
      // Register the user once
      await request(app).post('/api/auth/register').send(loginCredentials);

      // Exhaust the rate limit (e.g., 10 requests)
      const requests = [];
      for (let i = 0; i < 10; i++) {
        requests.push(request(app).post('/api/auth/login').send(loginCredentials));
      }
      await Promise.all(requests);

      // The next request should be rate-limited
      const res = await request(app).post('/api/auth/login').send(loginCredentials);
      expect(res.statusCode).toEqual(429);
    }, 15000); // Increase timeout for this test
  });

  describe('Input Validation (express-validator)', () => {
    describe('Registration Route', () => {
      it('should return 400 for an invalid email', async () => {
        const res = await request(app)
          .post('/api/auth/register')
          .send({ email: 'not-an-email', password: 'password123' });
        expect(res.statusCode).toEqual(400);
        expect(res.body.errors[0].msg).toBe('Please include a valid email');
      });

      it('should return 400 for a password shorter than 6 characters', async () => {
        const res = await request(app)
          .post('/api/auth/register')
          .send({ email: 'valid@example.com', password: '123' });
        expect(res.statusCode).toEqual(400);
        expect(res.body.errors[0].msg).toBe('Password must be at least 6 characters');
      });
    });

    describe('Product Creation Route', () => {
      it('should return 400 if product name is empty', async () => {
        const res = await request(app)
          .post('/api/products')
          .set('Authorization', `Bearer ${adminToken}`)
          .send({ name: '', description: 'A product', price: 10, category: 'Category' });
        expect(res.statusCode).toEqual(400);
        expect(res.body.errors[0].msg).toBe('Name is required');
      });

      it('should return 400 if price is not a positive number', async () => {
        const res = await request(app)
          .post('/api/products')
          .set('Authorization', `Bearer ${adminToken}`)
          .send({ name: 'Product Name', description: 'A product', price: -5, category: 'Category' });
        expect(res.statusCode).toEqual(400);
        expect(res.body.errors[0].msg).toBe('Price must be a positive number');
      });
    });
  });
});
