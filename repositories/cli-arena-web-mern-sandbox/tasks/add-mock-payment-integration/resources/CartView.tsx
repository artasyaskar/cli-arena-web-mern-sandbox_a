import { IProduct } from '../types';
import axios from 'axios';

interface CartViewProps {
    cart: Record<string, number>; // productId -> quantity
    products: IProduct[];
    token: string | null;
    onClose: () => void;
    onCheckoutSuccess: () => void;
}

export const CartView = ({ cart, products, token, onClose, onCheckoutSuccess }: CartViewProps) => {
    const cartItems = Object.keys(cart).map(productId => {
        const product = products.find(p => p._id === productId);
        return { ...product, quantity: cart[productId] };
    });

    const total = cartItems.reduce((sum, item) => sum + (item.price || 0) * item.quantity, 0);

    const handleCheckout = async (mockToken: 'tok_mock_success' | 'tok_mock_fail') => {
        if (!token) {
            alert('You must be logged in to check out.');
            return;
        }

        const items = Object.entries(cart).map(([productId, quantity]) => ({ productId, quantity }));

        try {
            await axios.post('/api/checkout/session', { items, paymentToken: mockToken }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert('Checkout successful!');
            onCheckoutSuccess();
        } catch (error: any) {
            alert(`Checkout failed: ${error.response?.data?.message || 'Unknown error'}`);
        }
    };

    return (
        <div className="cart-view">
            <h2>Shopping Cart</h2>
            {cartItems.length === 0 ? (
                <p>Your cart is empty.</p>
            ) : (
                <>
                    <ul>
                        {cartItems.map(item => (
                            <li key={item._id}>
                                {item.name} - ${item.price?.toFixed(2)} x {item.quantity}
                            </li>
                        ))}
                    </ul>
                    <h3>Total: ${total.toFixed(2)}</h3>
                    <button onClick={() => handleCheckout('tok_mock_success')}>Pay (Success)</button>
                    <button onClick={() => handleCheckout('tok_mock_fail')}>Pay (Fail)</button>
                </>
            )}
            <button onClick={onClose}>Close Cart</button>
        </div>
    );
};
