import multer from 'multer';
import multerS3 from 'multer-s3';
import { Request } from 'express';
import s3Client from '../config/s3';
import path from 'path';

const upload = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: process.env.S3_BUCKET_NAME!,
    metadata: function (req: Request, file: Express.Multer.File, cb: (error: Error | null, metadata?: any) => void) {
      cb(null, { fieldName: file.fieldname });
    },
    key: function (req: Request, file: Express.Multer.File, cb: (error: any, key?: string) => void) {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    },
  }),
  fileFilter: (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'));
    }
  },
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

export default upload;
