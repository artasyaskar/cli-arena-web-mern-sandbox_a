// tasks/add-e2e-tests-cypress/tests/seed-user.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// We need to define the Mongoose schema here because this script
// is run outside of the TypeScript application context.
const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, required: true, default: 'user' },
});

const User = mongoose.model('User', UserSchema);

const seedUser = async () => {
  const MONGO_URI = process.env.MONGO_URI;
  if (!MONGO_URI) {
    console.error('MONGO_URI environment variable is not set.');
    process.exit(1);
  }

  try {
    await mongoose.connect(MONGO_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('MongoDB connected for user seeding.');

    const email = 'admin@example.com';
    const password = 'password123';

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log('Admin user already exists.');
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({
      email,
      password: hashedPassword,
      role: 'admin', // The test expects an admin user
    });

    await newUser.save();
    console.log('Admin user seeded successfully.');

  } catch (err) {
    console.error('Error during user seeding:', err);
    process.exit(1);
  } finally {
    mongoose.connection.close();
    console.log('MongoDB connection closed after seeding.');
  }
};

seedUser();
