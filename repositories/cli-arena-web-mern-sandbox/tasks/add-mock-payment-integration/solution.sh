#!/usr/bin/env bash
set -euo pipefail

# This script implements the mock payment integration feature.

echo "--- Applying solution for task: add-mock-payment-integration ---"

# 1. Create Checkout controller
cat > src/server/src/controllers/checkoutController.ts << 'EOF'
import { Response } from 'express';
import { IAuthRequest } from '../middleware/auth';
import Purchase from '../models/Purchase';
import mongoose from 'mongoose';

interface CartItem {
    productId: string;
    quantity: number;
}

export const createCheckoutSession = async (req: IAuthRequest, res: Response) => {
    const { items, paymentToken } = req.body as { items: CartItem[], paymentToken: string };
    const userId = req.user!.id;

    if (!items || !paymentToken || !Array.isArray(items)) {
        return res.status(400).json({ message: 'Missing items or payment token' });
    }

    if (paymentToken === 'tok_mock_fail') {
        return res.status(400).json({ message: 'Payment failed' });
    }

    if (paymentToken !== 'tok_mock_success') {
        return res.status(400).json({ message: 'Invalid payment token' });
    }

    try {
        const purchasePromises = items.flatMap(item =>
            Array.from({ length: item.quantity }, () =>
                new Purchase({
                    userId,
                    productId: item.productId,
                }).save()
            )
        );

        await Promise.all(purchasePromises);

        res.status(200).json({ message: 'Checkout successful' });

    } catch (error) {
        console.error('Checkout error:', error);
        res.status(500).json({ message: 'Server error during checkout' });
    }
};
EOF


# 2. Create Checkout routes
cat > src/server/src/routes/checkoutRoutes.ts << 'EOF'
import { Router } from 'express';
import { protect } from '../middleware/auth';
import { createCheckoutSession } from '../controllers/checkoutController';

const router = Router();

router.route('/session').post(protect, createCheckoutSession);

export default router;
EOF


# 3. Hook up the new route in index.ts
sed -i'' -e "/import purchaseRoutes from '.\/routes\/purchaseRoutes';/a\\
import checkoutRoutes from './routes/checkoutRoutes';" src/server/src/index.ts

sed -i'' -e "/app.use('\/api\/purchase', purchaseRoutes);/a\\
app.use('/api/checkout', checkoutRoutes);" src/server/src/index.ts


# 4. Update the frontend by copying the new/modified components
cp tasks/add-mock-payment-integration/resources/CartView.tsx src/client/src/components/
cp tasks/add-mock-payment-integration/resources/ProductList.tsx src/client/src/components/
cp tasks/add-mock-payment-integration/resources/App.tsx src/client/src/


echo "--- Mock payment integration feature applied successfully. ---"
