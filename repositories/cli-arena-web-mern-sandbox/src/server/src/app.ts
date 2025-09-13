import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import productRoutes from './routes/productRoutes';

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// API Routes
import authRoutes from './routes/authRoutes';

app.get('/api/health', (req: Request, res: Response) => {
  res.status(200).json({ status: 'ok' });
});
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);

// --- Static files and SPA handler for production ---
if (process.env.NODE_ENV === 'production') {
  // The folder where the production client build is located
  const buildPath = path.join(__dirname, '..', 'public');
  app.use(express.static(buildPath));

  // For any request that doesn't match a static file or API route,
  // send back the main index.html file. This is for SPAs.
  app.get('*', (req, res) => {
    res.sendFile(path.join(buildPath, 'index.html'));
  });
}
// ---

export default app;
