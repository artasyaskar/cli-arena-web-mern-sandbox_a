import { useState, useEffect, FormEvent } from 'react';
import axios from 'axios';
import './App.css'; // Let's create a new css file for better styling

interface IProduct {
  _id: string;
  name: string;
  description: string;
  price: number;
  category: string;
}

function App() {
  const [products, setProducts] = useState<IProduct[]>([]);
  const [newProduct, setNewProduct] = useState({
    name: '',
    description: '',
    price: '',
    category: '',
  });
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const { data } = await axios.get('/api/products');
      setProducts(data);
      setError(null);
    } catch (err) {
      setError('Failed to fetch products.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setNewProduct(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    try {
      await axios.post('/api/products', {
        ...newProduct,
        price: parseFloat(newProduct.price)
      });
      setNewProduct({ name: '', description: '', price: '', category: '' });
      fetchProducts(); // Refresh the list
    } catch (err) {
      setError('Failed to create product.');
      console.error(err);
    }
  };

  return (
    <div className="container">
      <header>
        <h1>MERN Product Catalog</h1>
        <p>A baseline full-stack application.</p>
      </header>

      <main>
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

        <div className="products-container">
          <h2>Available Products</h2>
          {loading && <p>Loading products...</p>}
          {error && <p className="error">{error}</p>}
          {!loading && !error && (
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
        </div>
      </main>
    </div>
  );
}

export default App;
