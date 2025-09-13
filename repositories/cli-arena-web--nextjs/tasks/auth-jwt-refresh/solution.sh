#!/bin/bash

# 1. Install dependencies
npm install bcryptjs jsonwebtoken @prisma/client
npm install --save-dev @types/bcryptjs @types/jsonwebtoken

# 2. Update Prisma schema
cat > prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String         @id @default(cuid())
  email         String         @unique
  name          String
  password      String
  role          Role           @default(USER)
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt
  refreshTokens RefreshToken[]
}

model RefreshToken {
  id        String   @id @default(cuid())
  token     String   @unique
  userId    String
  expiresAt DateTime
  createdAt DateTime @default(now())
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

enum Role {
  USER
  EDITOR
  ADMIN
}
EOF

# 3. Create auth utilities
mkdir -p src/lib
cat > src/lib/auth.ts << 'EOF'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key'
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key'

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12)
}

export async function verifyPassword(password: string, hashedPassword: string): Promise<boolean> {
  return bcrypt.compare(password, hashedPassword)
}

export function generateAccessToken(userId: string, email: string, role: string): string {
  return jwt.sign({ userId, email, role }, JWT_SECRET, { expiresIn: '15m' })
}

export function generateRefreshToken(userId: string): string {
  return jwt.sign({ userId }, JWT_REFRESH_SECRET, { expiresIn: '7d' })
}

export function verifyAccessToken(token: string): any {
  try {
    return jwt.verify(token, JWT_SECRET)
  } catch (error) {
    return null
  }
}

export function verifyRefreshToken(token: string): any {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET)
  } catch (error) {
    return null
  }
}

export async function saveRefreshToken(userId: string, token: string): Promise<void> {
  const expiresAt = new Date()
  expiresAt.setDate(expiresAt.getDate() + 7)
  
  await prisma.refreshToken.create({
    data: {
      token,
      userId,
      expiresAt,
    },
  })
}

export async function deleteRefreshToken(token: string): Promise<void> {
  await prisma.refreshToken.deleteMany({
    where: { token },
  })
}

export async function findRefreshToken(token: string): Promise<any> {
  return prisma.refreshToken.findUnique({
    where: { token },
    include: { user: true },
  })
}
EOF

# 4. Create signup API route
mkdir -p src/pages/api/auth
cat > src/pages/api/auth/signup.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { PrismaClient } from '@prisma/client'
import { hashPassword } from '../../../lib/auth'

const prisma = new PrismaClient()

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { email, password, name } = req.body

    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password, and name are required' })
    }

    const existingUser = await prisma.user.findUnique({
      where: { email },
    })

    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' })
    }

    const hashedPassword = await hashPassword(password)

    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
      },
    })

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
    })
  } catch (error) {
    console.error('Signup error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}
EOF

# 5. Create login API route
cat > src/pages/api/auth/login.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { PrismaClient } from '@prisma/client'
import { verifyPassword, generateAccessToken, generateRefreshToken, saveRefreshToken } from '../../../lib/auth'

const prisma = new PrismaClient()

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { email, password } = req.body

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' })
    }

    const user = await prisma.user.findUnique({
      where: { email },
    })

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' })
    }

    const isValidPassword = await verifyPassword(password, user.password)

    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' })
    }

    const accessToken = generateAccessToken(user.id, user.email, user.role)
    const refreshToken = generateRefreshToken(user.id)

    await saveRefreshToken(user.id, refreshToken)

    res.status(200).json({
      message: 'Login successful',
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    })
  } catch (error) {
    console.error('Login error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}
EOF

# 6. Create refresh API route
cat > src/pages/api/auth/refresh.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { verifyRefreshToken, generateAccessToken, generateRefreshToken, saveRefreshToken, deleteRefreshToken, findRefreshToken } from '../../../lib/auth'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { refreshToken } = req.body

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' })
    }

    const decoded = verifyRefreshToken(refreshToken)
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid refresh token' })
    }

    const storedToken = await findRefreshToken(refreshToken)
    if (!storedToken) {
      return res.status(401).json({ error: 'Refresh token not found' })
    }

    if (new Date() > storedToken.expiresAt) {
      await deleteRefreshToken(refreshToken)
      return res.status(401).json({ error: 'Refresh token expired' })
    }

    const newAccessToken = generateAccessToken(storedToken.user.id, storedToken.user.email, storedToken.user.role)
    const newRefreshToken = generateRefreshToken(storedToken.user.id)

    await deleteRefreshToken(refreshToken)
    await saveRefreshToken(storedToken.user.id, newRefreshToken)

    res.status(200).json({
      message: 'Token refreshed successfully',
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    })
  } catch (error) {
    console.error('Refresh error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}
EOF

# 7. Create logout API route
cat > src/pages/api/auth/logout.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { deleteRefreshToken } from '../../../lib/auth'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const { refreshToken } = req.body

    if (refreshToken) {
      await deleteRefreshToken(refreshToken)
    }

    res.status(200).json({ message: 'Logout successful' })
  } catch (error) {
    console.error('Logout error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}
EOF

# 8. Create auth middleware
mkdir -p src/middleware
cat > src/middleware/auth.ts << 'EOF'
import { NextApiRequest, NextApiResponse } from 'next'
import { verifyAccessToken } from '../lib/auth'

export function withAuth(handler: any) {
  return async (req: NextApiRequest, res: NextApiResponse) => {
    const authHeader = req.headers.authorization

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Access token required' })
    }

    const token = authHeader.substring(7)
    const decoded = verifyAccessToken(token)

    if (!decoded) {
      return res.status(401).json({ error: 'Invalid access token' })
    }

    req.user = decoded
    return handler(req, res)
  }
}
EOF
