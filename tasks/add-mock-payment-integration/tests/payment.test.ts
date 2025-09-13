import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/index';
import Product from '../../../src/server/src/models/Product';
import Purchase from '../../../src/server/src/models/Purchase';
import User from '../../../src/server/src/models/User';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-payment';

let userToken: string;
let userId: string;
let product1: any;
let product2: any;

beforeAll(async () => {
  await mongoose.connect(MONGO_URI_TEST);

  await User.deleteMany({});
  await Product.deleteMany({});

  const userRes = await request(app).post('/api/auth/register').send({ email: 'payment@test.com', password: 'password123' });
  userToken = userRes.body.token;
  const user = await User.findOne({ email: 'payment@test.com' });
  userId = user!._id;

  product1 = await new Product({ name: 'Product A', price: 10 }).save();
  product2 = await new Product({ name: 'Product B', price: 20 }).save();
});

beforeEach(async () => {
    // Clear purchases before each test to ensure accurate counts
    await Purchase.deleteMany({});
});

afterAll(async () => {
  await mongoose.connection.close();
});

describe('POST /api/checkout/session', () => {
  it('should return 401 Unauthorized for unauthenticated requests', async () => {
    const res = await request(app).post('/api/checkout/session').send({});
    expect(res.statusCode).toBe(401);
  });

  it('should return 400 if the payment token is for a failed payment', async () => {
    const res = await request(app)
      .post('/api/checkout/session')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        items: [{ productId: product1._id, quantity: 1 }],
        paymentToken: 'tok_mock_fail',
      });

    expect(res.statusCode).toBe(400);
    expect(res.body.message).toBe('Payment failed');

    const purchaseCount = await Purchase.countDocuments();
    expect(purchaseCount).toBe(0);
  });

  it('should create purchase documents for a successful payment', async () => {
    const res = await request(app)
      .post('/api/checkout/session')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        items: [
          { productId: product1._id, quantity: 2 }, // Buying 2 of Product A
          { productId: product2._id, quantity: 1 }, // Buying 1 of Product B
        ],
        paymentToken: 'tok_mock_success',
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.message).toBe('Checkout successful');

    const purchases = await Purchase.find({ userId: userId });
    expect(purchases.length).toBe(3); // 2 of A, 1 of B

    const productAPurchases = await Purchase.countDocuments({ userId: userId, productId: product1._id });
    expect(productAPurchases).toBe(2);
  });

  it('should return 400 for an invalid payment token', async () => {
    const res = await request(app)
      .post('/api/checkout/session')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        items: [{ productId: product1._id, quantity: 1 }],
        paymentToken: 'tok_invalid_token',
      });

    expect(res.statusCode).toBe(400);
  });
});
