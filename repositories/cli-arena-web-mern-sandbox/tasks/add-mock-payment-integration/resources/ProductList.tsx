import { IProduct } from '../types';

interface ProductListProps {
  products: IProduct[];
  loading: boolean;
  error: string | null;
  onAddToCart: (productId: string) => void;
}

export const ProductList = ({ products, loading, error, onAddToCart }: ProductListProps) => {
    if (loading) return <p>Loading products...</p>;
    if (error) return <p className="error">{error}</p>;
    if (products.length === 0) return <p>No products found.</p>;

    return (
        <ul className="product-list">
            {products.map(product => (
            <li key={product._id} className="product-item">
                <h3>{product.name}</h3>
                {product.imageUrl && <img src={product.imageUrl} alt={product.name} style={{ maxWidth: '100px', marginTop: '10px' }} />}
                <span>({product.category})</span>
                <p>{product.description}</p>
                <p className="price">${product.price.toFixed(2)}</p>
                <button onClick={() => onAddToCart(product._id)}>Add to Cart</button>
            </li>
            ))}
        </ul>
    );
};
