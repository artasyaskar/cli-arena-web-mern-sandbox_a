#!/usr/bin/env bash
set -euo pipefail

# This script implements the JWT authentication feature.

# 1. Install required dependencies
sed -i'' -e '/"mongoose":/a\
    "jsonwebtoken": "^9.0.0",\
    "bcryptjs": "^2.4.3",' src/server/package.json

sed -i'' -e '/"@types\/node":/a\
    "@types/jsonwebtoken": "^9.0.1",\
    "@types/bcryptjs": "^2.4.2",' src/server/package.json


# 2. Create the User model
cat > src/server/src/models/User.ts << 'EOF'
import mongoose, { Document, Schema } from 'mongoose';
import bcrypt from 'bcryptjs';

export interface IUser extends Document {
  email: string;
  password?: string; // Optional because we don't return it
  comparePassword(password: string): Promise<boolean>;
}

const UserSchema: Schema = new Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    select: false, // Do not return password by default
  },
});

// Hash password before saving
UserSchema.pre<IUser>('save', async function (next) {
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Method to compare passwords
UserSchema.methods.comparePassword = function (password: string): Promise<boolean> {
  return bcrypt.compare(password, this.password);
};

const User = mongoose.model<IUser>('User', UserSchema);

export default User;
EOF


# 3. Create the authentication middleware
mkdir -p src/server/src/middleware
cat > src/server/src/middleware/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// Extend Express Request type to include user
export interface IAuthRequest extends Request {
  user?: { id: string };
}

export const protect = (req: IAuthRequest, res: Response, next: NextFunction) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'supersecretjwtkey') as { id: string };
      req.user = { id: decoded.id };
      next();
    } catch (error) {
      res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token' });
  }
};
EOF


# 4. Create the authentication routes
cat > src/server/src/routes/authRoutes.ts << 'EOF'
import { Router } from 'express';
import { registerUser, loginUser } from '../controllers/authController';

const router = Router();

router.post('/register', registerUser);
router.post('/login', loginUser);

export default router;
EOF


# 5. Create the authentication controller
cat > src/server/src/controllers/authController.ts << 'EOF'
import { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User';

const generateToken = (id: string) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'supersecretjwtkey', {
    expiresIn: '24h',
  });
};

export const registerUser = async (req: Request, res: Response) => {
  const { email, password } = req.body;
  try {
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists' });
    }
    const user = await User.create({ email, password });
    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(201).json({
        user: userResponse,
        token: generateToken(user._id)
    });
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

export const loginUser = async (req: Request, res: Response) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email }).select('+password');
    if (user && (await user.comparePassword(password))) {
      res.json({
        token: generateToken(user._id),
      });
    } else {
        const userExists = await User.findOne({ email });
        if (!userExists) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};
EOF


# 6. Modify server index.ts to use auth routes
sed -i'' -e "/import productRoutes from '.\/routes\/productRoutes';/a\\
import authRoutes from './routes/authRoutes';" src/server/src/index.ts

sed -i'' -e "/app.use('\/api\/products', productRoutes);/a\\
app.use('/api/auth', authRoutes);" src/server/src/index.ts


# 7. Modify productRoutes.ts to protect the POST route
sed -i'' -e "/import { getAllProducts, createProduct } from '..\/controllers\/productController';/a\\
import { protect } from '../middleware/auth';" src/server/src/routes/productRoutes.ts

sed -i'' -e "s/router.route('\/').get(getAllProducts).post(createProduct);/router.route('\/').get(getAllProducts).post(protect, createProduct);/" src/server/src/routes/productRoutes.ts


# 8. Update the frontend App.tsx to include auth functionality
cp tasks/add-jwt-authentication/resources/App.tsx src/client/src/App.tsx

echo "Task 'add-jwt-authentication' solution script applied."
