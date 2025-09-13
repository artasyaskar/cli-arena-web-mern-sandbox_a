#!/usr/bin/env bash
set -euo pipefail

# This script implements the full-text search feature.

echo "--- Applying solution for task: add-full-text-search ---"

# 1. Add text index to the Product model
sed -i'' -e "/default: Date.now,/a\\
});\
\
ProductSchema.index({ name: 'text', description: 'text' });" src/server/src/models/Product.ts


# 2. Add a search method to the ProductRepository
# We need to add a new function to the class in productRepository.ts
sed -i'' -e "/return product.save();/a\\
  }\
\
  async search(query: string): Promise<IProduct[]> {\
    return Product.find(\
      { \$text: { \$search: query } },\
      { score: { \$meta: 'textScore' } }\
    ).sort({ score: { \$meta: 'textScore' } });\
  " src/server/src/repositories/productRepository.ts


# 3. Add a search method to the ProductService
sed -i'' -e "/return productRepository.create(productData);/a\\
  }\
\
  async searchProducts(query: string): Promise<IProduct[]> {\
    return productRepository.search(query);\
  " src/server/src/services/productService.ts


# 4. Add a search function to the ProductController
sed -i'' -e "/res.status(201).json(newProduct);/a\\
  } catch (error) {\
    res.status(500).json({ message: 'Server Error' });\
  }\
};\
\
export const searchProducts = async (req: Request, res: Response) => {\
  try {\
    const query = req.query.q as string;\
    if (!query) {\
      return res.status(400).json({ message: 'Query parameter \"q\" is required' });\
    }\
    const products = await productService.searchProducts(query);\
    res.status(200).json(products);\
" src/server/src/controllers/productController.ts


# 5. Add the new route to productRoutes.ts
sed -i'' -e "/import { getAllProducts, createProduct } from '..\/controllers\/productController';/c\\
import { getAllProducts, createProduct, searchProducts } from '../controllers/productController';" src/server/src/routes/productRoutes.ts

sed -i'' -e "/.post(validateProductCreation, protect, admin, createProduct);/a\\
\
router.route('/search').get(searchProducts);" src/server/src/routes/productRoutes.ts


# 6. Overwrite App.tsx with the version from resources
cp tasks/add-full-text-search/resources/App.tsx src/client/src/App.tsx


echo "--- Full-text search feature applied successfully. ---"
