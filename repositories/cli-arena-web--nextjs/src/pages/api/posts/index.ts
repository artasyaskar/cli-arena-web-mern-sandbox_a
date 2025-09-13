import type { NextApiRequest, NextApiResponse } from 'next';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse,
): Promise<void> {
  try {
    switch (req.method) {
      case 'GET':
        const posts = await prisma.post.findMany({
          orderBy: { createdAt: 'desc' },
        });
        res.status(200).json(posts);
        break;

      case 'POST':
        const { title, content, published = false } = req.body;

        if (!title || !content) {
          return res.status(400).json({
            error: 'Title and content are required',
          });
        }

        const newPost = await prisma.post.create({
          data: {
            title,
            content,
            published: Boolean(published),
          },
        });

        res.status(201).json(newPost);
        break;

      default:
        res.setHeader('Allow', ['GET', 'POST']);
        res.status(405).json({
          error: `Method ${req.method} Not Allowed`,
        });
    }
  } catch (error) {
    console.error('API Error:', error);
    res.status(500).json({
      error: 'Internal server error',
    });
  }
}
