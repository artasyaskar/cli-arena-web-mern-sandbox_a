import { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import './App.css';
import { IProduct } from './types';
import { useDebounce } from './hooks';
import { AuthForm } from './components/AuthForm';
import { ProductList } from './components/ProductList';
import { AddProductForm } from './components/AddProductForm';
import { SearchBar } from './components/SearchBar';
import { Notifications } from './components/Notifications';
import { CartView } from './components/CartView';

// --- App Component ---
function App() {
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
  const [isAuth, setIsAuth] = useState<boolean>(!!token);
  const [view, setView] = useState<'login' | 'register' | 'catalog' | 'cart'>('catalog');
  const [notifications, setNotifications] = useState<string[]>([]);
  const [cart, setCart] = useState<Record<string, number>>({});
  const [products, setProducts] = useState<IProduct[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const debouncedSearchQuery = useDebounce(searchQuery, 300);

  const fetchProducts = useCallback(async () => {
    try {
        setLoading(true);
        const url = debouncedSearchQuery ? `/api/products/search?q=${debouncedSearchQuery}` : '/api/products';
        const { data } = await axios.get(url);
        setProducts(data);
        setError(null);
    } catch (err) {
        setError('Failed to fetch products.');
    } finally {
        setLoading(false);
    }
  }, [debouncedSearchQuery]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const handleSetToken = (newToken: string) => {
    localStorage.setItem('token', newToken);
    setToken(newToken);
    setIsAuth(true);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setToken(null);
    setIsAuth(false);
  };

  const handleAddToCart = (productId: string) => {
    setCart(prevCart => ({
      ...prevCart,
      [productId]: (prevCart[productId] || 0) + 1,
    }));
  };

  const handleCheckoutSuccess = () => {
    setCart({});
    setView('catalog');
  };

  const cartItemCount = Object.values(cart).reduce((sum, quantity) => sum + quantity, 0);

  return (
    <div className="container">
      <header>
        <h1>MERN Product Catalog</h1>
        <nav>
          {isAuth ? (
            <>
              <button onClick={() => setView('catalog')}>Catalog</button>
              <button onClick={() => setView('cart')}>Cart ({cartItemCount})</button>
              <button onClick={handleLogout}>Logout</button>
            </>
          ) : (
            <>
              <button onClick={() => setView('catalog')}>Catalog</button>
              <button onClick={() => setView('login')}>Login</button>
              <button onClick={() => setView('register')}>Register</button>
            </>
          )}
        </nav>
      </header>
      <Notifications notifications={notifications} />
      <main>
        {view === 'catalog' && (
            <ProductCatalogView
                token={token}
                onAddToCart={handleAddToCart}
                products={products}
                loading={loading}
                error={error}
                searchQuery={searchQuery}
                setSearchQuery={setSearchQuery}
                onProductAdded={fetchProducts}
            />
        )}
        {view === 'cart' && (
            <CartView
                cart={cart}
                products={products}
                token={token}
                onClose={() => setView('catalog')}
                onCheckoutSuccess={handleCheckoutSuccess}
            />
        )}
        {view === 'login' && <AuthForm mode="login" setToken={handleSetToken} setView={setView} />}
        {view === 'register' && <AuthForm mode="register" setToken={handleSetToken} setView={setView} />}
      </main>
    </div>
  );
}

const ProductCatalogView = (props: {
    token: string | null,
    onAddToCart: (productId: string) => void,
    products: IProduct[],
    loading: boolean,
    error: string | null,
    searchQuery: string,
    setSearchQuery: (q: string) => void,
    onProductAdded: () => void
}) => {
    const { token, onAddToCart, products, loading, error, searchQuery, setSearchQuery, onProductAdded } = props;

    return (
        <div>
            <SearchBar searchQuery={searchQuery} setSearchQuery={setSearchQuery} />
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '2rem' }}>
                <AddProductForm token={token} onProductAdded={onProductAdded} />
                <div className="products-container">
                    <h2>{searchQuery ? `Search Results` : 'Available Products'}</h2>
                    <ProductList products={products} loading={loading} error={error} onAddToCart={onAddToCart} />
                </div>
            </div>
        </div>
    );
};

export default App;
