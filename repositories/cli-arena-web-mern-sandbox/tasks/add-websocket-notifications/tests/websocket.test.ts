import request from 'supertest';
import mongoose from 'mongoose';
import { Server } from 'http';
import WebSocket from 'ws';
import app from '../../../src/server/src/index'; // This will be tricky, index needs to export the server
import User from '../../../src/server/src/models/User';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-ws';

let server: Server;
let port: number;
let adminToken: string;

beforeAll((done) => {
  mongoose.connect(MONGO_URI_TEST).then(() => {
    server = app.listen(0, async () => {
      const address = server.address();
      port = typeof address === 'string' ? 0 : address!.port;

      await User.deleteMany({});
      const regRes = await request(app).post('/api/auth/register').send({ email: 'ws@test.com', password: 'password123', role: 'admin' });
      adminToken = regRes.body.token;

      done();
    });
  });
});

afterAll((done) => {
  mongoose.connection.close().then(() => {
    server.close(done);
  });
});

describe('WebSocket Notifications', () => {
  it('should broadcast a "NEW_PRODUCT" message to clients when a new product is created', (done) => {
    const ws = new WebSocket(`ws://localhost:${port}`);

    const newProduct = {
      name: 'Real-time Gadget',
      description: 'A shiny new gadget.',
      price: 199.99,
      category: 'Real-time',
    };

    ws.on('open', () => {
      // Once the connection is open, create a new product via the REST API
      request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(newProduct)
        .expect(201); // We don't need to test the REST response here, just that it succeeds
    });

    ws.on('message', (message) => {
      // When we receive a message, check if it's the one we expect
      const data = JSON.parse(message.toString());

      expect(data.type).toBe('NEW_PRODUCT');
      expect(data.payload).toBeDefined();
      expect(data.payload.name).toBe(newProduct.name);

      ws.close();
      done();
    });

    ws.on('error', (err) => {
        done(err);
    });
  });
});
