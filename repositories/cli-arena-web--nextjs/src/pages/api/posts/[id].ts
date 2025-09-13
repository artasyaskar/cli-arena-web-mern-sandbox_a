import type { NextApiRequest, NextApiResponse } from 'next';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

interface UpdateData {
  title?: string;
  content?: string;
  published?: boolean;
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse,
): Promise<void> {
  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({
      error: 'Post ID is required',
    });
  }

  try {
    switch (req.method) {
      case 'GET':
        const post = await prisma.post.findUnique({
          where: { id },
        });

        if (!post) {
          return res.status(404).json({
            error: 'Post not found',
          });
        }

        res.status(200).json(post);
        break;

      case 'PUT':
        const { title, content, published } = req.body;

        if (!title && !content && published === undefined) {
          return res.status(400).json({
            error:
              'At least one field (title, content, or published) is required',
          });
        }

        const updateData: UpdateData = {};
        if (title !== undefined) updateData.title = title;
        if (content !== undefined) updateData.content = content;
        if (published !== undefined) updateData.published = Boolean(published);

        const updatedPost = await prisma.post.update({
          where: { id },
          data: updateData,
        });

        res.status(200).json(updatedPost);
        break;

      case 'DELETE':
        const deletedPost = await prisma.post.delete({
          where: { id },
        });

        res.status(200).json({
          message: 'Post deleted successfully',
          post: deletedPost,
        });
        break;

      default:
        res.setHeader('Allow', ['GET', 'PUT', 'DELETE']);
        res.status(405).json({
          error: `Method ${req.method} Not Allowed`,
        });
    }
  } catch (error: unknown) {
    if ((error as { code?: string }).code === 'P2025') {
      return res.status(404).json({
        error: 'Post not found',
      });
    }

    console.error('API Error:', error);
    res.status(500).json({
      error: 'Internal server error',
    });
  }
}
