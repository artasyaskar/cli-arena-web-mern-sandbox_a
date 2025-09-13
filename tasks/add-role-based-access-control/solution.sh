#!/usr/bin/env bash
set -euo pipefail

# This script implements Role-Based Access Control (RBAC).

echo "--- Applying solution for task: add-role-based-access-control ---"

# 1. Modify the User model to include a 'role' field
sed -i'' -e "/password?: string;/a\\
  role: string;" src/server/src/models/User.ts

sed -i'' -e "/select: false, \/ \/ Do not return password by default/a\\
  },\
  role: {\
    type: String,\
    enum: ['user', 'admin'],\
    default: 'user',\
  " src/server/src/models/User.ts


# 2. Modify the authentication middleware to add an 'admin' check
# We will overwrite the file with the new logic for 'protect' and the new 'admin' middleware.
cat > src/server/src/middleware/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User';

// Extend Express Request type to include user
export interface IAuthRequest extends Request {
  user?: { id:string, role: string };
}

export const protect = async (req: IAuthRequest, res: Response, next: NextFunction) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'supersecretjwtkey') as { id: string };

      const user = await User.findById(decoded.id).select('-password');
      if (!user) {
        return res.status(401).json({ message: 'Not authorized, user not found' });
      }

      req.user = { id: user.id, role: user.role };
      next();
    } catch (error) {
      res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token' });
  }
};

export const admin = (req: IAuthRequest, res: Response, next: NextFunction) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json({ message: 'Not authorized as an admin' });
    }
};
EOF


# 3. Create a new UserController to handle listing users
cat > src/server/src/controllers/userController.ts << 'EOF'
import { Request, Response } from 'express';
import User from '../models/User';

/**
 * @desc    Get all users
 * @route   GET /api/users
 * @access  Private/Admin
 */
export const getAllUsers = async (req: Request, res: Response) => {
  try {
    const users = await User.find({}).select('-password');
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};
EOF


# 4. Create a new UserRoutes file
cat > src/server/src/routes/userRoutes.ts << 'EOF'
import { Router } from 'express';
import { getAllUsers } from '../controllers/userController';
import { protect, admin } from '../middleware/auth';

const router = Router();

router.route('/').get(protect, admin, getAllUsers);

export default router;
EOF


# 5. Modify server index.ts to use the new user routes
sed -i'' -e "/import authRoutes from '.\/routes\/authRoutes';/a\\
import userRoutes from './routes/userRoutes';" src/server/src/index.ts

sed -i'' -e "/app.use('\/api\/auth', authRoutes);/a\\
app.use('/api/users', userRoutes);" src/server/src/index.ts


# 6. Modify productRoutes.ts to use the 'admin' middleware
sed -i'' -e "/import { protect } from '..\/middleware\/auth';/a\\
import { admin } from '../middleware/auth';" src/server/src/routes/productRoutes.ts

sed -i'' -e "s/router.route('\/').get(getAllProducts).post(protect, createProduct);/router.route('\/').get(getAllProducts).post(protect, admin, createProduct);/" src/server/src/routes/productRoutes.ts


# 7. Update the DB seed script to create an admin user
cat > db/seed.js << 'EOF'
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');

dotenv.config({ path: './src/server/.env' });

const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
});
const User = mongoose.model('User', UserSchema);

const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true },
  category: { type: String, required: true },
});
const Product = mongoose.model('Product', ProductSchema);


const seedDB = async () => {
  const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/mern-sandbox';

  try {
    await mongoose.connect(MONGO_URI);
    console.log('MongoDB connected for seeding.');

    // Clear existing data
    await Product.deleteMany({});
    await User.deleteMany({});
    console.log('Collections cleared.');

    // Create admin user
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('password123', salt);
    await User.create({
        email: 'admin@example.com',
        password: hashedPassword,
        role: 'admin'
    });
    console.log('Admin user created.');

    // Insert sample products
    const sampleProducts = [
      { name: 'Laptop Pro', description: 'High-performance laptop.', price: 1499.99, category: 'Electronics' },
      { name: 'The Pragmatic Programmer', description: 'A classic book.', price: 39.99, category: 'Books' },
    ];
    await Product.insertMany(sampleProducts);
    console.log('Sample products inserted.');

    console.log('Database seeding completed successfully!');
  } catch (err) {
    console.error('Error during database seeding:', err);
    process.exit(1);
  } finally {
    mongoose.connection.close();
    console.log('MongoDB connection closed.');
  }
};

seedDB();
EOF

echo "Task 'add-role-based-access-control' solution script applied."
