#!/usr/bin/env bash
set -euo pipefail

# This script introduces a race condition bug into the auth middleware
# for the 'fix-jwt-race-condition' task.

echo "--- Introducing bug for task: fix-jwt-race-condition ---"

# 1. Add 'isActive' field to the User model
sed -i'' -e "/role: string;/a\\
  isActive: boolean;" src/server/src/models/User.ts

sed -i'' -e "/default: 'user',/a\\
  },\
  isActive: {\
    type: Boolean,\
    default: true,\
  " src/server/src/models/User.ts


# 2. Add 'logout' and 'me' endpoints
sed -i'' -e "/import { registerUser, loginUser } from '..\/controllers\/authController';/a\\
import { logoutUser, getMe } from '../controllers/authController';" src/server/src/routes/authRoutes.ts
sed -i'' -e "/import { protect } from '..\/middleware\/auth';/d" src/server/src/routes/authRoutes.ts # remove unused import if present
sed -i'' -e "/import { registerUser, loginUser } from '..\/controllers\/authController';/a\\
import { protect } from '../middleware/auth';" src/server/src/routes/authRoutes.ts


sed -i'' -e "/router.post('\/login', loginUser);/a\\
router.post('/logout', protect, logoutUser);\
router.get('/me', protect, getMe);" src/server/src/routes/authRoutes.ts

# Add the controller functions to authController.ts
cat >> src/server/src/controllers/authController.ts << 'EOF'

export const logoutUser = async (req: IAuthRequest, res: Response) => {
    try {
        const user = await User.findById(req.user.id);
        if (user) {
            user.isActive = false;
            await user.save();
            res.status(200).json({ message: 'User logged out successfully' });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

export const getMe = async (req: IAuthRequest, res: Response) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};
EOF'
sed -i'' -e "/import User from '..\/models\/User';/a\\
import { IAuthRequest } from '../middleware/auth';" src/server/src/controllers/authController.ts


# 3. Modify the 'protect' middleware to introduce the race condition
cat > src/server/src/middleware/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/User';

// A dummy async function to simulate a delay
const simulateAsyncOperation = () => new Promise(resolve => setTimeout(resolve, 50));

export interface IAuthRequest extends Request {
  user?: { id: string, role: string };
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

      // THE BUG IS HERE: We check the user's status, then await, then call next().
      // If the status changes during the await, we will proceed with an invalid user.
      if (!user.isActive) {
        return res.status(401).json({ message: 'Not authorized, user is inactive' });
      }

      req.user = { id: user.id, role: user.role };

      // Simulate a database call or other async work.
      await simulateAsyncOperation();

      // By the time we get here, the user might have logged out,
      // but we are not re-checking their status.
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

echo "--- Bug introduced successfully. ---"
