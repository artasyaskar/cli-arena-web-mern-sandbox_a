import { Request, Response } from 'express';
import Product from '../models/Product';
import productRepository from '../repositories/productRepository';

/**
 * @desc    Get all products with purchase counts
 * @route   GET /api/products
 * @access  Public
 */
export const getAllProducts = async (req: Request, res: Response) => {
  try {
    const products = await productRepository.findAll();
    res.status(200).json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ message: 'Server Error' });
  }
};

/**
 * @desc    Upload an image for a product
 * @route   POST /api/products/:id/image
 * @access  Private/Admin
 */
export const uploadImage = async (req: Request, res: Response) => {
  try {
    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    if (!req.file) {
      return res.status(400).json({ message: 'Please upload a file' });
    }

    // The `req.file` object now comes from multer-s3
    const imageUrl = (req.file as any).location;
    if (!imageUrl) {
      return res.status(500).json({ message: 'Error uploading file to S3' });
    }

    product.imageUrl = imageUrl;
    const updatedProduct = await product.save();

    res.status(200).json({
      message: 'Image uploaded successfully',
      imageUrl: imageUrl,
      product: updatedProduct,
    });
  } catch (error) {
    console.error('Error in uploadImage controller:', error);
    res.status(500).json({ message: 'Server Error' });
  }
};

/**
 * @desc    Create a new product
 * @route   POST /api/products
 * @access  Public
 */
export const createProduct = async (req: Request, res: Response) => {
  try {
    const { name, description, price, category } = req.body;

    if (!name || !description || !price || !category) {
      return res.status(400).json({ message: 'Please provide all required fields' });
    }

    const newProduct = new Product({
      name,
      description,
      price,
      category,
    });

    const savedProduct = await newProduct.save();
    res.status(201).json(savedProduct);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};
