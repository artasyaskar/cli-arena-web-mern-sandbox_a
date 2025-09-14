#!/bin/bash
set -e

# This script introduces a bug into the product controller for the k8s crash scenario.

# The bug will be in a new 'checkout' function.
# A specific discount code will cause the server to crash.

TARGET_FILE="src/server/src/controllers/productController.ts"

# Use a here-document to append the new buggy function to the controller file.
cat <<'EOF' >> $TARGET_FILE

/**
 * @desc    Process a product checkout
 * @route   POST /api/products/checkout
 * @access  Public
 */
export const checkout = async (req: Request, res: Response) => {
  try {
    const { productId, discountCode } = req.body;

    // Second crash scenario: specific product ID causes a crash
    if (productId === '60d5f3b3b4854b32348a22a4') {
      throw new Error('Critical failure for special product ID');
    }

    const product = await Product.findById(productId);

    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    let finalPrice = product.price;

    if (discountCode) {
      // This is the intentional bug.
      // If the discount code is CRASHTEST, we try to access a property on 'promoDetails', which is undefined.
      let promoDetails;
      if (discountCode === 'CRASHTEST') {
        console.log(`Applying special discount: ${promoDetails.code}`); // This will crash
      }
    }

    // In a real app, you'd have more logic here (e.g., payment processing)
    res.status(200).json({ message: 'Checkout successful', productId, finalPrice });

  } catch (error) {
    console.error('Error during checkout:', error);
    // Ensure the process exits to simulate a crash that brings the pod down
    process.exit(1);
  }
};
EOF

# Now, we also need to add a route for this new controller function.
# We'll append it to the product routes file.
ROUTES_FILE="src/server/src/routes/productRoutes.ts"

# First, read the existing file and remove the router export.
# We need to insert the new route before the export.
head -n -1 $ROUTES_FILE > temp_routes.ts
echo "router.post('/checkout', checkout);" >> temp_routes.ts
echo "export default router;" >> temp_routes.ts
mv temp_routes.ts $ROUTES_FILE

# Finally, we need to import the 'checkout' function in the routes file.
# We'll use sed to add it to the import statement.
sed -i "s/{\s*getAllProducts,\s*createProduct,\s*uploadImage\s*}/{\ getAllProducts, createProduct, uploadImage, checkout }/" $ROUTES_FILE

echo "Bug introduced into product controller and route added."
