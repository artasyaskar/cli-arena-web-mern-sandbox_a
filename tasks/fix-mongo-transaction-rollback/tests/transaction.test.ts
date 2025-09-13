import request from 'supertest';
import mongoose from 'mongoose';
import app from '../../../src/server/src/index';
import Product from '../../../src/server/src/models/Product';
import Purchase from '../../../src/server/src/models/Purchase';
import User from '../../../src/server/src/models/User';

// Note: For this test to pass, MongoDB must be running as a replica set.
// The solution.sh for this task is expected to modify the docker-compose.yml.
const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-txn?replicaSet=rs0';

let userToken: string;
let userId: string;
let productWithLowStock: any;

beforeAll(async () => {
    // It can take a moment for the replica set to elect a primary.
    // We add a small delay and retry mechanism.
    let connected = false;
    for (let i = 0; i < 5; i++) {
        try {
            await mongoose.connect(MONGO_URI_TEST);
            connected = true;
            break;
        } catch (e) {
            console.log('Connection failed, retrying...');
            await new Promise(res => setTimeout(res, 1000));
        }
    }
    if (!connected) throw new Error('Could not connect to MongoDB replica set');

    await User.deleteMany({});
    await Product.deleteMany({});

    const userRes = await request(app).post('/api/auth/register').send({ email: 'txn@test.com', password: 'password123' });
    userToken = userRes.body.token;
    const user = await User.findOne({ email: 'txn@test.com' });
    userId = user!._id;
});

beforeEach(async () => {
    await Purchase.deleteMany({});
    await Product.deleteMany({});
    productWithLowStock = await new Product({ name: 'Limited Edition Widget', price: 50, stock: 1 }).save();
});

afterAll(async () => {
  await mongoose.connection.close();
});

describe('Checkout Transaction Atomicity', () => {
  it('should fail the checkout if stock is insufficient', async () => {
    const res = await request(app)
      .post('/api/checkout/session')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        items: [{ productId: productWithLowStock._id, quantity: 2 }], // Try to buy 2 when stock is 1
        paymentToken: 'tok_mock_success',
      });

    expect(res.statusCode).toBe(400);
    expect(res.body.message).toContain('Insufficient stock');
  });

  it('should NOT create any purchase records if the transaction fails midway', async () => {
    // This is the key test. The buggy code will fail this assertion.
    await request(app)
      .post('/api/checkout/session')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        items: [{ productId: productWithLowStock._id, quantity: 2 }],
        paymentToken: 'tok_mock_success',
      });

    const purchaseCount = await Purchase.countDocuments({ userId: userId });
    expect(purchaseCount).toBe(0);
  });

  it('should decrement stock and create purchases on a successful transaction', async () => {
    await request(app)
        .post('/api/checkout/session')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
            items: [{ productId: productWithLowStock._id, quantity: 1 }], // Buy exactly the amount in stock
            paymentToken: 'tok_mock_success',
        });

    const purchaseCount = await Purchase.countDocuments({ userId: userId });
    expect(purchaseCount).toBe(1);

    const product = await Product.findById(productWithLowStock._id);
    expect(product!.stock).toBe(0);
  });
});
