#!/usr/bin/env bash
set -euo pipefail

# This script refactors the backend to a layered architecture.

echo "--- Applying solution for task: refactor-layered-architecture ---"

# 1. Create the new directory structure
mkdir -p src/server/src/services
mkdir -p src/server/src/repositories


# 2. Create the Product Repository (DAL)
cat > src/server/src/repositories/productRepository.ts << 'EOF'
import Product, { IProduct } from '../models/Product';

class ProductRepository {
  async findAll(): Promise<IProduct[]> {
    return Product.find({});
  }

  async create(productData: Partial<IProduct>): Promise<IProduct> {
    const product = new Product(productData);
    return product.save();
  }
}

export default new ProductRepository();
EOF


# 3. Create the Product Service (Business Logic Layer)
cat > src/server/src/services/productService.ts << 'EOF'
import productRepository from '../repositories/productRepository';
import { IProduct } from '../models/Product';

class ProductService {
  async getAllProducts(): Promise<IProduct[]> {
    return productRepository.findAll();
  }

  async createProduct(productData: { name: string; description: string; price: number; category: string; }): Promise<IProduct> {
    // In a real app, more complex business logic would go here.
    // For example, checking inventory, validating against other systems, etc.
    return productRepository.create(productData);
  }
}

export default new ProductService();
EOF


# 4. Create the Auth Service (Business Logic Layer)
cat > src/server/src/services/authService.ts << 'EOF'
import User, { IUser } from '../models/User';
import jwt from 'jsonwebtoken';

class AuthService {
  private generateToken(id: string): string {
    return jwt.sign({ id }, process.env.JWT_SECRET || 'supersecretjwtkey', {
      expiresIn: '24h',
    });
  }

  async register(userData: Pick<IUser, 'email' | 'password'>): Promise<{ user: Partial<IUser>, token: string }> {
    const userExists = await User.findOne({ email: userData.email });
    if (userExists) {
      throw new Error('User already exists');
    }

    const user = await User.create({ email: userData.email, password: userData.password });

    const userResponse = user.toObject();
    delete userResponse.password;

    return {
      user: userResponse,
      token: this.generateToken(user._id),
    };
  }

  async login(credentials: Pick<IUser, 'email' | 'password'>): Promise<{ token: string } | null> {
    const user = await User.findOne({ email: credentials.email }).select('+password');

    if (user && (await user.comparePassword(credentials.password))) {
      return { token: this.generateToken(user._id) };
    }

    // To provide specific error messages, we check if the user exists at all
    if (!user) {
        throw new Error('User not found');
    }

    return null; // Indicates invalid credentials if user was found
  }
}

export default new AuthService();
EOF


# 5. Refactor the Product Controller (API Layer)
cat > src/server/src/controllers/productController.ts << 'EOF'
import { Request, Response } from 'express';
import productService from '../services/productService';

export const getAllProducts = async (req: Request, res: Response) => {
  try {
    const products = await productService.getAllProducts();
    res.status(200).json(products);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

export const createProduct = async (req: Request, res: Response) => {
  try {
    const { name, description, price, category } = req.body;
    const newProduct = await productService.createProduct({ name, description, price, category });
    res.status(201).json(newProduct);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};
EOF


# 6. Refactor the Auth Controller (API Layer)
cat > src/server/src/controllers/authController.ts << 'EOF'
import { Request, Response } from 'express';
import authService from '../services/authService';
import { IAuthRequest } from '../middleware/auth';
import User from '../models/User'; // Still needed for logout/getMe

export const registerUser = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    const result = await authService.register({ email, password });
    res.status(201).json(result);
  } catch (error: any) {
    if (error.message === 'User already exists') {
      return res.status(400).json({ message: error.message });
    }
    res.status(500).json({ message: 'Server Error' });
  }
};

export const loginUser = async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    const result = await authService.login({ email, password });
    if (result) {
      res.json(result);
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error: any) {
    if (error.message === 'User not found') {
        return res.status(404).json({ message: error.message });
    }
    res.status(500).json({ message: 'Server Error' });
  }
};

// These two can remain as they are simpler and less business-logic heavy
export const logoutUser = async (req: IAuthRequest, res: Response) => {
    try {
        const user = await User.findById(req.user!.id);
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
        const user = await User.findById(req.user!.id).select('-password');
        res.status(200).json(user);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};
EOF

echo "--- Backend refactoring applied successfully. ---"
