#!/usr/bin/env bash
set -euo pipefail

# This script fixes the race condition in the auth middleware.

echo "--- Applying solution for task: fix-jwt-race-condition ---"

# The fix is to re-check the user's status after any async operations
# within the middleware, just before calling next().

# We will overwrite the 'protect' middleware function with the corrected logic.
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

      let user = await User.findById(decoded.id).select('-password');

      if (!user || !user.isActive) {
        return res.status(401).json({ message: 'Not authorized, user invalid or inactive' });
      }

      req.user = { id: user.id, role: user.role };

      // Simulate a database call or other async work.
      await simulateAsyncOperation();

      // THE FIX: Re-fetch the user or at least their status after the async gap.
      user = await User.findById(decoded.id).select('isActive');

      if (!user || !user.isActive) {
        return res.status(401).json({ message: 'Not authorized, user logged out during request processing' });
      }

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

echo "--- Solution applied successfully. ---"
