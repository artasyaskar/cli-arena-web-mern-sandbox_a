import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/index';
import User from '../../../src/server/src/models/User';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-rbac';

let adminToken: string;
let userToken: string;
let adminUserId: string;

// Hooks for database connection and setup
beforeAll(async () => {
  await mongoose.connect(MONGO_URI_TEST);

  // Setup Admin and Regular User
  await User.deleteMany({});

  // Create admin user directly
  const admin = new User({ email: 'admin@example.com', password: 'password123', role: 'admin' });
  await admin.save();
  adminUserId = admin._id;

  // Register a regular user
  await request(app).post('/api/auth/register').send({ email: 'user@example.com', password: 'password123' });

  // Login as admin to get token
  const adminLoginRes = await request(app).post('/api/auth/login').send({ email: 'admin@example.com', password: 'password123' });
  adminToken = adminLoginRes.body.token;

  // Login as user to get token
  const userLoginRes = await request(app).post('/api/auth/login').send({ email: 'user@example.com', password: 'password123' });
  userToken = userLoginRes.body.token;
});

afterAll(async () => {
  await mongoose.connection.close();
});


describe('Role-Based Access Control (RBAC)', () => {
  const newProduct = {
    name: 'Admin-Only Product',
    description: 'This product requires admin rights to create.',
    price: 99.99,
    category: 'Exclusive',
  };

  describe('Product Creation (/api/products)', () => {
    it('should return 403 Forbidden for a regular user trying to create a product', async () => {
      const res = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${userToken}`)
        .send(newProduct);

      // On the previous task's solution, this would be 201. The goal is to make it 403.
      expect(res.statusCode).toEqual(403);
    });

    it('should return 201 Created for an admin user creating a product', async () => {
      const res = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(newProduct);

      expect(res.statusCode).toEqual(201);
      expect(res.body.name).toBe(newProduct.name);
    });
  });

  describe('User List (/api/users)', () => {
    it('should return 403 Forbidden for a regular user trying to list users', async () => {
      const res = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${userToken}`);

      // On the previous task's solution, this would be 404. The goal is to make it 403.
      expect(res.statusCode).toEqual(403);
    });

    it('should return 401 Unauthorized if no token is provided', async () => {
        const res = await request(app).get('/api/users');
        expect(res.statusCode).toEqual(401);
    });

    it('should return 200 OK and a list of users for an admin', async () => {
      const res = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.statusCode).toEqual(200);
      expect(res.body).toBeInstanceOf(Array);
      // We created an admin and a regular user
      expect(res.body.length).toBe(2);
      expect(res.body.some((u: any) => u.email === 'admin@example.com')).toBe(true);
    });
  });

  describe('User Model', () => {
      it('should assign "user" role by default upon registration', async () => {
        await request(app).post('/api/auth/register').send({ email: 'defaultrole@example.com', password: 'password123' });
        const newUser = await User.findOne({email: 'defaultrole@example.com'});
        expect(newUser.role).toBe('user');
      });
  });
});
