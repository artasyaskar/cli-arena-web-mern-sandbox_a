#!/usr/bin/env bash
set -euo pipefail

# This script fixes the N+1 query problem by using a MongoDB aggregation pipeline.

echo "--- Applying solution for task: optimize-mongo-queries ---"

# The only file that needs to change is the productRepository.ts.
# We will replace the inefficient `findAll` method with an efficient one.

cat > src/server/src/repositories/productRepository.ts << 'EOF'
import Product, { IProduct } from '../models/Product';
import Purchase from '../models/Purchase';
import mongoose from 'mongoose';

class ProductRepository {
  async findAll(): Promise<IProduct[]> {
    // This is the efficient solution using an aggregation pipeline.
    const products = await Product.aggregate([
      {
        // Join with the 'purchases' collection
        $lookup: {
          from: 'purchases', // The collection name in the DB
          localField: '_id',
          foreignField: 'productId',
          as: 'purchaseData',
        },
      },
      {
        // Add a new field 'purchaseCount' which is the size of the joined array
        $addFields: {
          purchaseCount: { $size: '$purchaseData' },
        },
      },
      {
        // Remove the temporary 'purchaseData' field from the final output
        $project: {
          purchaseData: 0,
        },
      },
    ]);
    return products;
  }

  async create(productData: Partial<IProduct>): Promise<IProduct> {
    const product = new Product(productData);
    return product.save();
  }

  async search(query: string): Promise<IProduct[]> {
    // Note: search results won't have the purchase count for this task's scope.
    return Product.find(
      { $text: { $search: query } },
      { score: { $meta: 'textScore' } }
    ).sort({ score: { $meta: 'textScore' } });
  }
}

export default new ProductRepository();
EOF

echo "--- Efficient aggregation pipeline implemented successfully. ---"
