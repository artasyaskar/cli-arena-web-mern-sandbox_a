#!/usr/bin/env bash
set -euo pipefail

# This script implements the WebSocket real-time notification feature.

echo "--- Applying solution for task: add-websocket-notifications ---"

# 1. Install dependencies
sed -i'' -e '/"express-validator":/a\
    "ws": "^8.13.0",' src/server/package.json
sed -i'' -e '/"@types\/helmet":/a\
    "@types/ws": "^8.5.4",' src/server/package.json


# 2. Create the websockets.ts module
cat > src/server/src/websockets.ts << 'EOF'
import { WebSocketServer, WebSocket } from 'ws';
import { Server } from 'http';

let wss: WebSocketServer;

export const initWebSocketServer = (server: Server) => {
  wss = new WebSocketServer({ server });

  wss.on('connection', (ws: WebSocket) => {
    console.log('Client connected to WebSocket');
    ws.on('close', () => console.log('Client disconnected'));
  });

  console.log('WebSocket server initialized');
};

export const broadcast = (message: object) => {
  if (!wss) {
    console.error('WebSocket server not initialized.');
    return;
  }

  const data = JSON.stringify(message);
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });
};
EOF


# 3. Refactor index.ts to use http.Server explicitly
replace_with_git_merge_diff src/server/src/index.ts << 'EOF'
<<<<<<< SEARCH
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import path from 'path';
import helmet from 'helmet';

// Import routes
import productRoutes from './routes/productRoutes';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/products', productRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.get('/api/health', (req, res) => res.status(200).json({ status: 'ok' }));

// --- Static files and SPA handler for production ---
if (process.env.NODE_ENV === 'production') {
    const buildPath = path.join(__dirname, '..', 'public');
    app.use(express.static(buildPath));
    app.get('*', (req, res) => {
        res.sendFile(path.join(buildPath, 'index.html'));
    });
}

// Database connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb://mongo:27017/mern-sandbox';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('MongoDB connected successfully.');
    app.listen(PORT, () => {
      console.log(`Server is running on http://localhost:${PORT}`);
    });
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });

export default app;
=======
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import path from 'path';
import helmet from 'helmet';
import { createServer } from 'http';
import { initWebSocketServer } from './websockets';

// Import routes
import productRoutes from './routes/productRoutes';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';

dotenv.config();

const app = express();
const httpServer = createServer(app); // Create HTTP server

// Init WebSocket server
initWebSocketServer(httpServer);

const PORT = process.env.PORT || 8080;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/products', productRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.get('/api/health', (req, res) => res.status(200).json({ status: 'ok' }));

// --- Static files and SPA handler for production ---
if (process.env.NODE_ENV === 'production') {
  const buildPath = path.join(__dirname, '..', 'public');
  app.use(express.static(buildPath));
  app.get('*', (req, res) => {
    res.sendFile(path.join(buildPath, 'index.html'));
  });
}

// Database connection
const MONGO_URI = process.env.MONGO_URI || 'mongodb://mongo:27017/mern-sandbox';

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('MongoDB connected successfully.');
    httpServer.listen(PORT, () => { // Use httpServer to listen
      console.log(`Server is running on http://localhost:${PORT}`);
    });
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });

export default httpServer; // Export the server for testing
>>>>>>> REPLACE
EOF


# 4. Modify productService.ts to broadcast the new product
sed -i'' -e "/import { IProduct } from '..\/models\/Product';/a\\
import { broadcast } from '../websockets';" src/server/src/services/productService.ts

# This is a bit tricky. We need to capture the result of create, then broadcast, then return.
# Using a block with sed to perform the replacement.
sed -i'' -e 's/return productRepository.create(productData);/{ \
    const newProduct = await productRepository.create(productData); \
    broadcast({ type: "NEW_PRODUCT", payload: newProduct }); \
    return newProduct; \
}/' src/server/src/services/productService.ts


# 5. Update frontend with WebSocket logic
mkdir -p src/client/src/hooks
mkdir -p src/client/src/components
cp tasks/add-websocket-notifications/resources/useProductWebSocket.ts src/client/src/hooks/
cp tasks/add-websocket-notifications/resources/Notifications.tsx src/client/src/components/
cp tasks/add-websocket-notifications/resources/App.tsx src/client/src/


echo "--- WebSocket feature applied successfully. ---"
