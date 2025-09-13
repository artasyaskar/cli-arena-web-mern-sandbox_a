import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/index';
import User from '../../../src/server/src/models/User';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-race';

let token: string;

beforeAll(async () => {
  await mongoose.connect(MONGO_URI_TEST);
});

afterAll(async () => {
  await mongoose.connection.close();
});

beforeEach(async () => {
  await User.deleteMany({});

  // Register and login a user to get a fresh token for each test
  const testUser = { email: 'race@example.com', password: 'password123' };
  await request(app).post('/api/auth/register').send(testUser);
  const loginRes = await request(app).post('/api/auth/login').send(testUser);
  token = loginRes.body.token;
});

describe('JWT Middleware Race Condition', () => {
  it('should prevent access to a protected route if the user logs out during middleware execution', async () => {
    // The buggy code will fail this test by returning a 200 for the '/api/auth/me' request.
    // The correct behavior is for the '/api/auth/me' request to fail with 401.

    const protectedRequest = request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`);

    const logoutRequest = request(app)
      .post('/api/auth/logout')
      .set('Authorization', `Bearer ${token}`);

    // Run both requests concurrently
    const [protectedResponse, logoutResponse] = await Promise.all([
      protectedRequest,
      logoutRequest,
    ]);

    // The logout request should always be successful.
    expect(logoutResponse.statusCode).toBe(200);

    // The protected request should fail because the user was logged out
    // while the request was "in-flight" in the middleware's async gap.
    expect(protectedResponse.statusCode).toBe(401);
    expect(protectedResponse.body.message).toContain('Not authorized');
  });
});
