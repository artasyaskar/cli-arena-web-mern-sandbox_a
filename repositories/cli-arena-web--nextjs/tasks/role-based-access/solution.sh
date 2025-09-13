#!/bin/bash

# 1. Update Prisma schema
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

# 2. Create RBAC middleware
mkdir -p src/middleware
cat > src/middleware/rbac.ts << 'EOF'
import { NextApiRequest, NextApiResponse } from 'next'
import { verifyAccessToken } from '../lib/auth'

export function hasRole(userRole: string, requiredRole: string): boolean {
  const roleHierarchy = { USER: 1, EDITOR: 2, ADMIN: 3 }
  return roleHierarchy[userRole] >= roleHierarchy[requiredRole]
}

export function withRole(requiredRole: string) {
  return function(handler: any) {
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

      if (!hasRole(decoded.role, requiredRole)) {
        return res.status(403).json({ error: 'Insufficient permissions' })
      }

      req.user = decoded
      return handler(req, res)
    }
  }
}

export const withAdminRole = withRole('ADMIN')
export const withEditorRole = withRole('EDITOR')
export const withUserRole = withRole('USER')
EOF

# 3. Update signup API route
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
    const { email, password, name, role = 'USER' } = req.body

    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, password, and name are required' })
    }

    if (!['USER', 'EDITOR', 'ADMIN'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' })
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
        role,
      },
    })

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    })
  } catch (error) {
    console.error('Signup error:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
}
EOF

# 4. Update login API route
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

# 5. Create admin data API route
mkdir -p src/pages/api/admin
cat > src/pages/api/admin/data.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { withAdminRole } from '../../../middleware/rbac'

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  res.status(200).json({
    message: 'Admin data accessed successfully',
    data: {
      users: 150,
      posts: 1200,
      comments: 5000,
      analytics: {
        dailyActiveUsers: 2500,
        monthlyRevenue: 15000,
        systemHealth: 'excellent'
      }
    },
    user: req.user
  })
}

export default withAdminRole(handler)
EOF

# 6. Create editor data API route
mkdir -p src/pages/api/editor
cat > src/pages/api/editor/data.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { withEditorRole } from '../../../middleware/rbac'

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  res.status(200).json({
    message: 'Editor data accessed successfully',
    data: {
      posts: 1200,
      drafts: 45,
      published: 1155,
      pendingReview: 12
    },
    user: req.user
  })
}

export default withEditorRole(handler)
EOF

# 7. Create user data API route
mkdir -p src/pages/api/user
cat > src/pages/api/user/data.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { withUserRole } from '../../../middleware/rbac'

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  res.status(200).json({
    message: 'User data accessed successfully',
    data: {
      profile: {
        name: req.user.name,
        email: req.user.email,
        role: req.user.role,
        joinDate: '2024-01-15'
      },
      stats: {
        posts: 5,
        comments: 23,
        likes: 156
      }
    },
    user: req.user
  })
}

export default withUserRole(handler)
EOF
