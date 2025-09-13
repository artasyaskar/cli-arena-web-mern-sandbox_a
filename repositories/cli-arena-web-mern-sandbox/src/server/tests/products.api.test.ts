import request from 'supertest';
import { Server } from 'http';
import app from '../src/app'; // Import the configured express app
import { connectDB, disconnectDB } from '../src/config/database';
import Product from '../src/models/Product';

const MONGO_URI_TEST = process.env.MONGO_URI_TEST || 'mongodb://mongo:27017/mern-sandbox-test';

let server: Server;

// Hooks for database connection and server management
beforeAll(async () => {
  await connectDB(MONGO_URI_TEST);
  server = app.listen(0); // Listen on a random, available port
});

afterAll(async () => {
  await disconnectDB();
  await new Promise<void>((resolve) => server.close(() => resolve()));
});

beforeEach(async () => {
  // Clear the collection before each test
  await Product.deleteMany({});
});


describe('Product API', () => {

  describe('GET /api/products', () => {
    it('should return an empty array when no products exist', async () => {
      const res = await request(server).get('/api/products');
      expect(res.statusCode).toEqual(200);
      expect(res.body).toBeInstanceOf(Array);
      expect(res.body.length).toBe(0);
    });

    it('should return all products when products exist', async () => {
      // Seed one product
      await new Product({ name: 'Test Product', description: 'A test', price: 100, category: 'Testing' }).save();
      
      const res = await request(server).get('/api/products');
      expect(res.statusCode).toEqual(200);
      expect(res.body.length).toBe(1);
      expect(res.body[0].name).toBe('Test Product');
    });
  });

  describe('POST /api/products', () => {
    const validProduct = {
      name: 'New Gadget',
      description: 'The latest and greatest gadget.',
      price: 999.99,
      category: 'Electronics',
    };

    it('should create a new product when given valid data', async () => {
      const res = await request(server)
        .post('/api/products')
        .send(validProduct);
      
      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('_id');
      expect(res.body.name).toBe(validProduct.name);

      // Verify the product was actually saved to the DB
      const productsInDb = await Product.find({});
      expect(productsInDb.length).toBe(1);
      expect(productsInDb[0].name).toBe(validProduct.name);
    });

    it('should return 400 Bad Request if required fields are missing', async () => {
      const invalidProduct = {
        name: 'Incomplete Product',
        // Missing description, price, category
      };

      const res = await request(server)
        .post('/api/products')
        .send(invalidProduct);

      expect(res.statusCode).toEqual(400);
      expect(res.body.message).toBe('Please provide all required fields');
    });
  });
});
