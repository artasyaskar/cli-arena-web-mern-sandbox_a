import { useState, useEffect, FormEvent, useCallback } from 'react';
import axios from 'axios';
import './App.css';

// Interfaces
interface IProduct {
  _id: string;
  name: string;
  description: string;
  price: number;
  category: string;
}

// --- Debounce Hook ---
const useDebounce = (value: string, delay: number) => {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);
  return debouncedValue;
};

// --- App Component ---
function App() {
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
  const [isAuth, setIsAuth] = useState<boolean>(!!token);
  const [view, setView] = useState<'login' | 'register' | 'catalog'>('catalog');

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

  return (
    <div className="container">
      <header>
        <h1>MERN Product Catalog</h1>
        <p>A baseline full-stack application with search!</p>
        <nav>
          {isAuth ? (
            <>
              <button onClick={() => setView('catalog')}>Catalog</button>
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

      <main>
        {view === 'catalog' && <ProductCatalog token={token} />}
        {view === 'login' && <AuthForm mode="login" setToken={handleSetToken} setView={setView} />}
        {view === 'register' && <AuthForm mode="register" setToken={handleSetToken} setView={setView} />}
      </main>
    </div>
  );
}

// --- Auth Form Component ---
const AuthForm = ({ mode, setToken, setView }: { mode: 'login' | 'register', setToken: (t: string) => void, setView: (v: 'catalog') => void }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const url = mode === 'login' ? '/api/auth/login' : '/api/auth/register';
    try {
      const { data } = await axios.post(url, { email, password });
      setToken(data.token);
      setView('catalog');
    } catch (err: any) {
      setError(err.response?.data?.message || 'An error occurred');
    }
  };

  return (
    <div className="form-container" style={{ maxWidth: '400px', margin: 'auto' }}>
      <h2>{mode === 'login' ? 'Login' : 'Register'}</h2>
      <form onSubmit={handleSubmit}>
        <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="Email" required />
        <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Password" required />
        {error && <p className="error">{error}</p>}
        <button type="submit">{mode === 'login' ? 'Login' : 'Register'}</button>
      </form>
    </div>
  );
};


// --- Product Catalog Component ---
const ProductCatalog = ({ token }: { token: string | null }) => {
  const [products, setProducts] = useState<IProduct[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [newProduct, setNewProduct] = useState({ name: '', description: '', price: '', category: '' });
  const [searchQuery, setSearchQuery] = useState('');
  const debouncedSearchQuery = useDebounce(searchQuery, 300);

  const fetchProducts = useCallback(async () => {
    try {
      setLoading(true);
      const url = debouncedSearchQuery
        ? `/api/products/search?q=${debouncedSearchQuery}`
        : '/api/products';
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

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setNewProduct(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!token) {
        setError("You must be logged in to create a product.");
        return;
    }
    try {
      await axios.post('/api/products', {
        ...newProduct,
        price: parseFloat(newProduct.price)
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setNewProduct({ name: '', description: '', price: '', category: '' });
      fetchProducts();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to create product.');
    }
  };

  return (
    <div>
        <div className="search-bar" style={{ marginBottom: '1rem' }}>
            <input
                type="text"
                placeholder="Search for products by name or description..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ width: '100%', padding: '0.75rem' }}
            />
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '2rem' }}>
            {token && (
                <div className="form-container">
                  <h2>Add New Product</h2>
                  <form onSubmit={handleSubmit}>
                    <input name="name" value={newProduct.name} onChange={handleInputChange} placeholder="Product Name" required />
                    <textarea name="description" value={newProduct.description} onChange={handleInputChange} placeholder="Product Description" required />
                    <input name="price" value={newProduct.price} onChange={handleInputChange} placeholder="Price" type="number" step="0.01" required />
                    <input name="category" value={newProduct.category} onChange={handleInputChange} placeholder="Category" required />
                    <button type="submit">Add Product</button>
                  </form>
                </div>
            )}
            <div className="products-container">
                <h2>{debouncedSearchQuery ? `Search Results for "${debouncedSearchQuery}"` : 'Available Products'}</h2>
                {loading && <p>Loading products...</p>}
                {error && <p className="error">{error}</p>}
                {!loading && !error && products.length > 0 && (
                    <ul className="product-list">
                        {products.map(product => (
                        <li key={product._id} className="product-item">
                            <h3>{product.name}</h3>
                            <span>({product.category})</span>
                            <p>{product.description}</p>
                            <p className="price">${product.price.toFixed(2)}</p>
                        </li>
                        ))}
                    </ul>
                )}
                {!loading && !error && products.length === 0 && (
                    <p>No products found matching your query.</p>
                )}
            </div>
        </div>
    </div>
  );
};

export default App;
