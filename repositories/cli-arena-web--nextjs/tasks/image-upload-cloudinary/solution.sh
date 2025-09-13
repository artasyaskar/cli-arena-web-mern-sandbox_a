#!/bin/bash

# 1. Install dependencies
npm install cloudinary multer
npm install --save-dev @types/multer

# 2. Create environment variables
cat > .env.local << 'EOF'
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
MAX_FILE_SIZE=5242880
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif,image/webp
EOF

# 3. Create upload API route
mkdir -p src/pages/api
cat > src/pages/api/upload.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next'
import { v2 as cloudinary } from 'cloudinary'
import multer from 'multer'

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
})

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE || '5242880') },
  fileFilter: (req, file, cb) => {
    const allowedTypes = (process.env.ALLOWED_FILE_TYPES || 'image/jpeg,image/png,image/gif,image/webp').split(',')
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true)
    } else {
      cb(new Error('Invalid file type'))
    }
  },
})

const runMiddleware = (req: NextApiRequest, res: NextApiResponse, fn: any) => {
  return new Promise((resolve, reject) => {
    fn(req, res, (result: any) => {
      if (result instanceof Error) return reject(result)
      return resolve(result)
    })
  })
}

export default async function handler(req: any, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      return res.status(500).json({ error: 'Cloudinary credentials not configured' })
    }

    await runMiddleware(req, res, upload.single('image'))

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' })
    }

    const base64File = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`

    const uploadResult = await cloudinary.uploader.upload(base64File, {
      folder: 'nextjs-uploads',
      resource_type: 'auto',
      transformation: [
        { width: 800, height: 600, crop: 'limit' },
        { quality: 'auto' },
        { fetch_format: 'auto' }
      ]
    })

    res.status(200).json({
      success: true,
      url: uploadResult.secure_url,
      publicId: uploadResult.public_id,
      width: uploadResult.width,
      height: uploadResult.height,
      format: uploadResult.format,
      size: uploadResult.bytes,
      message: 'Image uploaded successfully'
    })

  } catch (error) {
    console.error('Upload error:', error)
    
    if (error instanceof Error) {
      if (error.message === 'Invalid file type') {
        return res.status(400).json({ error: 'Invalid file type. Only images are allowed.' })
      }
      if (error.message.includes('File too large')) {
        return res.status(400).json({ error: 'File too large. Maximum size is 5MB.' })
      }
    }
    
    res.status(500).json({ error: 'Upload failed' })
  }
}

export const config = {
  api: { bodyParser: false },
}
EOF
