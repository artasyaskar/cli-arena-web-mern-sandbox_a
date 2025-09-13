#!/usr/bin/env bash
set -euo pipefail

# This script introduces the data integrity bug for the 'fix-mongo-transaction-rollback' task.

echo "--- Introducing bug for task: fix-mongo-transaction-rollback ---"

# 1. Add 'stock' field to the Product model
sed -i'' -e "/imageUrl?: string;/a\\
  stock: number;" src/server/src/models/Product.ts

sed -i'' -e "/imageUrl: { type: String },/a\\
  stock: { type: Number, required: true, default: 100 },\
" src/server/src/models/Product.ts


# 2. Modify the checkoutController to perform non-atomic operations
# This new version first creates purchases, then separately tries to update stock.
cat > src/server/src/controllers/checkoutController.ts << 'EOF'
import { Response } from 'express';
import { IAuthRequest } from '../middleware/auth';
import Purchase from '../models/Purchase';
import Product from '../models/Product'; // Need Product model now
import mongoose from 'mongoose';

interface CartItem {
    productId: string;
    quantity: number;
}

export const createCheckoutSession = async (req: IAuthRequest, res: Response) => {
    const { items, paymentToken } = req.body as { items: CartItem[], paymentToken: string };
    const userId = req.user!.id;

    if (paymentToken !== 'tok_mock_success') {
        return res.status(400).json({ message: 'Payment failed or invalid token' });
    }

    // THE BUG: These operations are not atomic.
    try {
        // Step 1: Create the purchase records
        const purchasePromises = items.flatMap(item =>
            Array.from({ length: item.quantity }, () =>
                new Purchase({ userId, productId: item.productId }).save()
            )
        );
        await Promise.all(purchasePromises);

        // Step 2: Decrement stock
        for (const item of items) {
            const product = await Product.findById(item.productId);
            if (!product || product.stock < item.quantity) {
                // This error happens AFTER purchases have already been saved.
                throw new Error('Insufficient stock for product: ' + (product ? product.name : item.productId));
            }
            product.stock -= item.quantity;
            await product.save();
        }

        res.status(200).json({ message: 'Checkout successful' });

    } catch (error: any) {
        // The purchases are NOT rolled back, leaving inconsistent data.
        res.status(400).json({ message: error.message });
    }
};
EOF

echo "--- Data integrity bug introduced successfully. ---"
