import mongoose from 'mongoose';

const connectDB = async (mongoUri: string) => {
  try {
    await mongoose.connect(mongoUri);
    console.log('MongoDB connected successfully.');
  } catch (err) {
    console.error('MongoDB connection error:', err);
    process.exit(1); // Exit process with failure
  }
};

const disconnectDB = async () => {
  try {
    await mongoose.connection.close();
    console.log('MongoDB connection closed.');
  } catch (err) {
    console.error('Error closing MongoDB connection:', err);
  }
};

export { connectDB, disconnectDB };
