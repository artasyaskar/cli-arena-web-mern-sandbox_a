#!/usr/bin/env bash
set -euo pipefail

# This script implements security enhancements: Helmet, Rate Limiting, and Input Validation.

echo "--- Applying solution for task: add-security-enhancements ---"

# 1. Install required dependencies
sed -i'' -e '/"mongoose":/a\
    "helmet": "^6.1.5",\
    "express-rate-limit": "^6.7.0",\
    "express-validator": "^7.0.1",' src/server/package.json

sed -i'' -e '/"@types\/node":/a\
    "@types/helmet": "^4.0.0",' src/server/package.json


# 2. Apply Helmet in index.ts
sed -i'' -e "/import cors from 'cors';/a\\
import helmet from 'helmet';" src/server/src/index.ts

sed -i'' -e "/const app = express();/a\\
app.use(helmet());" src/server/src/index.ts


# 3. Apply Rate Limiting to the login route in authRoutes.ts
sed -i'' -e "/import { Router } from 'express';/a\\
import rateLimit from 'express-rate-limit';" src/server/src/routes/authRoutes.ts

# Define the limiter
sed -i'' -e "/const router = Router();/a\\
const loginLimiter = rateLimit({\
    windowMs: 60 * 1000, // 1 minute\
    max: 10, // Limit each IP to 10 login requests per windowMs\
    message: 'Too many login attempts from this IP, please try again after a minute',\
    standardHeaders: true, // Return rate limit info in the \`RateLimit-*\` headers\
    legacyHeaders: false, // Disable the \`X-RateLimit-*\` headers\
});" src/server/src/routes/authRoutes.ts

# Apply it to the login route
sed -i'' -e "s/router.post('\/login', loginUser);/router.post('\/login', loginLimiter, loginUser);/" src/server/src/routes/authRoutes.ts


# 4. Create validation middleware and apply it
cat > src/server/src/middleware/validation.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { body, validationResult } from 'express-validator';

export const validateRegistration = [
  body('email', 'Please include a valid email').isEmail(),
  body('password', 'Password must be at least 6 characters').isLength({ min: 6 }),
  (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  },
];

export const validateProductCreation = [
  body('name', 'Name is required').not().isEmpty(),
  body('price', 'Price must be a positive number').isFloat({ gt: 0 }),
  body('category', 'Category is required').not().isEmpty(),
  (req: Request, res: Response, next: NextFunction) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    next();
  },
];
EOF

# Apply validation to authRoutes.ts
sed -i'' -e "/import { registerUser, loginUser } from '..\/controllers\/authController';/a\\
import { validateRegistration } from '../middleware/validation';" src/server/src/routes/authRoutes.ts

sed -i'' -e "s/router.post('\/register', registerUser);/router.post('\/register', validateRegistration, registerUser);/" src/server/src/routes/authRoutes.ts

# Apply validation to productRoutes.ts
sed -i'' -e "/import { protect, admin } from '..\/middleware\/auth';/a\\
import { validateProductCreation } from '../middleware/validation';" src/server/src/routes/productRoutes.ts

sed -i'' -e "s/.post(protect, admin, createProduct);/.post(validateProductCreation, protect, admin, createProduct);/" src/server/src/routes/productRoutes.ts


echo "--- Security enhancements applied successfully. ---"
