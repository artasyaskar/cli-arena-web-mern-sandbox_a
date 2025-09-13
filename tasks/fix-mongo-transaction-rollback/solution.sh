#!/usr/bin/env bash
set -euo pipefail

# This script fixes the data integrity issue by using MongoDB transactions.

echo "--- Applying solution for task: fix-mongo-transaction-rollback ---"

# 1. Modify docker-compose.yml to run MongoDB as a replica set
# This is required for transactions to work.
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
    working_dir: /app/server
    ports:
      - "8080:8080"
      - "3000:3000"
    environment:
      - MONGO_URI=mongodb://mongo:27017/mern-sandbox?replicaSet=rs0
      - PORT=8080
      - CHOKIDAR_USEPOLLING=true
    depends_on:
      - mongo
    volumes:
      - ./src/server:/app/server
      - ./src/client:/app/client
      - server_node_modules:/app/server/node_modules
      - client_node_modules:/app/client/node_modules
    command: npm run dev

  mongo:
    image: mongo:latest
    command: ["--replSet", "rs0", "--bind_ip_all"]
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    healthcheck:
        test: |
          mongosh --eval 'try { rs.status().ok } catch (e) { rs.initiate({ _id: "rs0", members: [ { _id: 0, host: "localhost:27017" } ] ) }'
        interval: 5s
        timeout: 30s
        start_period: 5s
        retries: 5

  mongo-express:
    image: mongo-express:latest
    ports:
      - "8081:8081"
    environment:
      - ME_CONFIG_MONGODB_SERVER=mongo
      - ME_CONFIG_MONGODB_PORT=27017
      - ME_CONFIG_MONGODB_ENABLE_ADMIN=false
      - ME_CONFIG_MONGODB_AUTH_DATABASE=admin
      - ME_CONFIG_MONGODB_REPLICA_SET_NAME=rs0
    depends_on:
      - mongo

volumes:
  mongo-data:
  server_node_modules:
  client_node_modules:
EOF


# 2. Refactor the checkoutController to use a transaction
cat > src/server/src/controllers/checkoutController.ts << 'EOF'
import { Response } from 'express';
import { IAuthRequest } from '../middleware/auth';
import Purchase from '../models/Purchase';
import Product from '../models/Product';
import mongoose from 'mongoose';

interface CartItem {
    productId: string;
    quantity: number;
}

export const createCheckoutSession = async (req: IAuthRequest, res: Response) => {
    const { items, paymentToken } = req.body as { items: CartItem[], paymentToken: string };
    const userId = req.user!.id;

    if (paymentToken !== 'tok_mock_success') {
        return res.status(400).json({ message: 'Payment failed or invalid token' });
    }

    // THE FIX: Use a transaction to ensure atomicity.
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        for (const item of items) {
            const product = await Product.findById(item.productId).session(session);
            if (!product || product.stock < item.quantity) {
                throw new Error('Insufficient stock for product: ' + (product ? product.name : item.productId));
            }

            // Decrement stock within the transaction
            product.stock -= item.quantity;
            await product.save({ session });

            // Create purchase records within the transaction
            for (let i = 0; i < item.quantity; i++) {
                const purchase = new Purchase({ userId, productId: item.productId });
                await purchase.save({ session });
            }
        }

        await session.commitTransaction();
        res.status(200).json({ message: 'Checkout successful' });

    } catch (error: any) {
        await session.abortTransaction();
        res.status(400).json({ message: error.message });
    } finally {
        session.endSession();
    }
};
EOF

echo "--- MongoDB transaction logic applied successfully. ---"
