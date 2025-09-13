import { Router } from 'express';
import { getAllProducts, createProduct, uploadImage } from '../controllers/productController';
import { protect, admin } from '../middleware/authMiddleware';
import upload from '../middleware/upload';

const router = Router();

router.route('/')
  .get(getAllProducts)
  .post(createProduct);

router.route('/:id/image')
  .post(protect, admin, upload.single('image'), uploadImage);

export default router;
