#!/bin/bash

# 1. Install dependencies
npm install @prisma/client
npm install --save-dev prisma

# 2. Create Prisma schema
cat > prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String
  published Boolean  @default(false)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("posts")
}
EOF

# 3. Create posts API route
mkdir -p src/pages/api/posts
cat > src/pages/api/posts/index.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    switch (req.method) {
      case 'GET':
        const posts = await prisma.post.findMany({
          orderBy: { createdAt: 'desc' }
        })
        res.status(200).json(posts)
        break

      case 'POST':
        const { title, content, published = false } = req.body

        if (!title || !content) {
          return res.status(400).json({
            error: 'Title and content are required'
          })
        }

        const newPost = await prisma.post.create({
          data: {
            title,
            content,
            published: Boolean(published)
          }
        })

        res.status(201).json(newPost)
        break

      default:
        res.setHeader('Allow', ['GET', 'POST'])
        res.status(405).json({
          error: `Method ${req.method} Not Allowed`
        })
    }
  } catch (error) {
    console.error('API Error:', error)
    res.status(500).json({
      error: 'Internal server error'
    })
  }
}
EOF

# 4. Create post by ID API route
cat > src/pages/api/posts/[id].ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { id } = req.query

  if (!id || typeof id !== 'string') {
    return res.status(400).json({
      error: 'Post ID is required'
    })
  }

  try {
    switch (req.method) {
      case 'GET':
        const post = await prisma.post.findUnique({
          where: { id }
        })

        if (!post) {
          return res.status(404).json({
            error: 'Post not found'
          })
        }

        res.status(200).json(post)
        break

      case 'PUT':
        const { title, content, published } = req.body

        if (!title && !content && published === undefined) {
          return res.status(400).json({
            error: 'At least one field (title, content, or published) is required'
          })
        }

        const updateData: any = {}
        if (title !== undefined) updateData.title = title
        if (content !== undefined) updateData.content = content
        if (published !== undefined) updateData.published = Boolean(published)

        const updatedPost = await prisma.post.update({
          where: { id },
          data: updateData
        })

        res.status(200).json(updatedPost)
        break

      case 'DELETE':
        const deletedPost = await prisma.post.delete({
          where: { id }
        })

        res.status(200).json({
          message: 'Post deleted successfully',
          post: deletedPost
        })
        break

      default:
        res.setHeader('Allow', ['GET', 'PUT', 'DELETE'])
        res.status(405).json({
          error: `Method ${req.method} Not Allowed`
        })
    }
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({
        error: 'Post not found'
      })
    }

    console.error('API Error:', error)
    res.status(500).json({
      error: 'Internal server error'
    })
  }
}
EOF

# 5. Create seed script
mkdir -p scripts
cat > scripts/seed.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Seeding database...')

  await prisma.post.deleteMany()

  const posts = await Promise.all([
    prisma.post.create({
      data: {
        title: 'First Post',
        content: 'This is the content of the first post.',
        published: true
      }
    }),
    prisma.post.create({
      data: {
        title: 'Second Post',
        content: 'This is the content of the second post.',
        published: false
      }
    }),
    prisma.post.create({
      data: {
        title: 'Third Post',
        content: 'This is the content of the third post.',
        published: true
      }
    })
  ])

  console.log('✅ Database seeded successfully!')
  console.log('Created posts:', posts.length)
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
EOF