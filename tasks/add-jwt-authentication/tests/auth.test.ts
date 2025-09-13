import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/index';
import User from '../../../src/server/src/models/User';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-auth';

// Hooks for database connection
beforeAll(async () => {
  await mongoose.connect(MONGO_URI_TEST);
});

afterAll(async () => {
  await mongoose.connection.close();
});

beforeEach(async () => {
  // Check if the User model exists before trying to delete
  if (mongoose.models.User) {
    await User.deleteMany({});
  }
});

describe('Auth API', () => {
  const testUser = {
    email: 'test@example.com',
    password: 'password123',
  };

  describe('POST /api/auth/register', () => {
    it('should register a new user and return the user object without the password', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(testUser);

      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(testUser.email);
      expect(res.body.user).not.toHaveProperty('password');
    });

    it('should not store the password in plaintext', async () => {
      await request(app)
        .post('/api/auth/register')
        .send(testUser);

      const userInDb = await User.findOne({ email: testUser.email });
      expect(userInDb).not.toBeNull();
      expect(userInDb.password).not.toBe(testUser.password);
    });

    it('should return 400 if user already exists', async () => {
      // Create user first
      await request(app).post('/api/auth/register').send(testUser);
      // Try to create it again
      const res = await request(app).post('/api/auth/register').send(testUser);
      expect(res.statusCode).toEqual(400);
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      // Register user before each login test
      await request(app).post('/api/auth/register').send(testUser);
    });

    it('should log in a registered user and return a JWT', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: testUser.email, password: testUser.password });

      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body.token).not.toBeNull();
    });

    it('should return 401 for incorrect password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: testUser.email, password: 'wrongpassword' });

      expect(res.statusCode).toEqual(401);
    });

    it('should return 404 for a non-existent user', async () => {
        const res = await request(app)
          .post('/api/auth/login')
          .send({ email: 'nouser@example.com', password: 'password123' });

        expect(res.statusCode).toEqual(404);
      });
  });
});
