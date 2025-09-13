import app from './app';
import { connectDB } from './config/database';
import dotenv from 'dotenv';

dotenv.config();

const PORT = process.env.PORT || 8080;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://mongo:27017/mern-sandbox';

const startServer = async () => {
  await connectDB(MONGO_URI);

  app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
  });
};

startServer();
