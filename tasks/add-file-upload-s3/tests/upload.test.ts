import request from 'supertest';
import mongoose from 'mongoose';
import path from 'path';
import fs from 'fs';
import app from '../../../src/server/src/app';
import Product from '../../../src/server/src/models/Product';
import User from '../../../src/server/src/models/User';
import { connectDB, disconnectDB } from '../../../src/server/src/config/database';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test-upload';

let adminToken: string;
let product: any;

const UPLOADS_DIR = path.join(__dirname, '..', '..', '..', 'uploads');

beforeAll(async () => {
  await connectDB(MONGO_URI_TEST);

  // Clean up previous test runs
  await User.deleteMany({});
  await Product.deleteMany({});
  if (fs.existsSync(UPLOADS_DIR)) {
    fs.rmSync(UPLOADS_DIR, { recursive: true, force: true });
  }

  // Create user and product for testing
  const regRes = await request(app).post('/api/auth/register').send({ email: 'upload@test.com', password: 'password123', role: 'admin' });
  adminToken = regRes.body.token;

  product = await new Product({ name: 'Upload Test Product', description: 'desc', price: 10, category: 'cat' }).save();
});

afterAll(async () => {
  await disconnectDB();
  if (fs.existsSync(UPLOADS_DIR)) {
    fs.rmSync(UPLOADS_DIR, { recursive: true, force: true });
  }
});

describe('POST /api/products/:id/image', () => {
  it('should upload an image and update the product imageUrl', async () => {
    const imagePath = path.join(__dirname, '..', 'resources', 'test-image.png');

    const res = await request(app)
      .post(`/api/products/${product._id}/image`)
      .set('Authorization', `Bearer ${adminToken}`)
      .attach('image', imagePath); // 'image' is the field name for multer

    expect(res.statusCode).toBe(200);
    expect(res.body.imageUrl).toBeDefined();
    expect(res.body.imageUrl).toContain('test-image'); // Check if the filename is in the URL

    // Verify in DB
    const updatedProduct = await Product.findById(product._id);
    expect(updatedProduct).not.toBeNull();
    expect(updatedProduct!.imageUrl).toEqual(res.body.imageUrl);

    // With S3, we don't check the local filesystem.
    // Instead, we could optionally make a HEAD request to the imageUrl to ensure it's accessible.
    // For this test, we'll trust that a successful upload returns a valid URL.
  });

  it('should return 403 if a non-admin tries to upload an image', async () => {
    // Create a regular user
    const userRes = await request(app).post('/api/auth/register').send({ email: 'nonadmin@test.com', password: 'password123' });
    const userToken = userRes.body.token;
    const imagePath = path.join(__dirname, '..', 'resources', 'test-image.png');

    const res = await request(app)
      .post(`/api/products/${product._id}/image`)
      .set('Authorization', `Bearer ${userToken}`)
      .attach('image', imagePath);

    expect(res.statusCode).toBe(403);
  });

  it('should return 400 if no file is provided', async () => {
    const res = await request(app)
      .post(`/api/products/${product._id}/image`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.statusCode).toBe(400);
  });
});
