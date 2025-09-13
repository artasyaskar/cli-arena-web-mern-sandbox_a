import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import productRepository from '../src/repositories/productRepository';
import Product from '../src/models/Product';
import Purchase from '../src/models/Purchase';

describe('Product Repository', () => {
  let mongoServer: MongoMemoryServer;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri);
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    await Product.deleteMany({});
    await Purchase.deleteMany({});
  });

  describe('findAll', () => {
    it('should return all products with purchase counts', async () => {
      const product1 = await Product.create({ name: 'Product 1', description: 'Desc 1', price: 10, category: 'Category 1' });
      const product2 = await Product.create({ name: 'Product 2', description: 'Desc 2', price: 20, category: 'Category 2' });

      await Purchase.create({ productId: product1._id, userId: new mongoose.Types.ObjectId(), quantity: 1, totalPrice: 10 });
      await Purchase.create({ productId: product1._id, userId: new mongoose.Types.ObjectId(), quantity: 1, totalPrice: 10 });
      await Purchase.create({ productId: product2._id, userId: new mongoose.Types.ObjectId(), quantity: 1, totalPrice: 20 });

      const products = await productRepository.findAll();

      expect(products).toHaveLength(2);
      const p1 = products.find(p => (p as any).name === 'Product 1');
      const p2 = products.find(p => (p as any).name === 'Product 2');

      if (p1 && p2) {
        expect((p1 as any).purchaseCount).toBe(2);
        expect((p2 as any).purchaseCount).toBe(1);
      } else {
        fail('Products not found in result');
      }
    });

    it('should return an empty array if there are no products', async () => {
        const products = await productRepository.findAll();
        expect(products).toEqual([]);
    });
  });

  describe('create', () => {
    it('should create a new product', async () => {
      const productData = { name: 'New Product', description: 'A great new product', price: 99.99, category: 'New' };
      const product = await productRepository.create(productData);

      expect(product).toBeDefined();
      expect(product.name).toBe(productData.name);

      const dbProduct = await Product.findById(product._id);
      expect(dbProduct).toBeDefined();
    });
  });

  describe('search', () => {
    beforeEach(async () => {
        // We need to create a text index on the model for text search to work
        await Product.collection.createIndex({ name: "text", description: "text" });
        await Product.create({ name: 'Laptop Pro', description: 'A powerful laptop', price: 1500, category: 'Electronics' });
        await Product.create({ name: 'Coffee Mug', description: 'A simple mug', price: 15, category: 'Kitchen' });
    });

    it('should return products that match the search query', async () => {
      const products = await productRepository.search('laptop');
      expect(products).toHaveLength(1);
      expect(products[0].name).toBe('Laptop Pro');
    });

    it('should return an empty array if no products match the query', async () => {
        const products = await productRepository.search('nonexistent');
        expect(products).toEqual([]);
    });
  });
});
