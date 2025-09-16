const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const medicineRoutes = require('./routes/medicines');
const authRoutes = require('./routes/auth'); // Import the new auth routes
const dotenv = require('dotenv'); // Import dotenv for environment variables

dotenv.config(); // Load environment variables from .env file

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to MongoDB Atlas
const MONGODB_URI = process.env.MONGODB_URI; // Use environment variable for the URI

mongoose.connect(MONGODB_URI)
  .then(() => console.log('Successfully connected to MongoDB Atlas.'))
  .catch(err => console.error('Connection error:', err));

// Middleware
app.use(cors()); // Enables Cross-Origin Resource Sharing for your Flutter app
app.use(express.json()); // Parses incoming JSON requests

// Routes
app.use('/api/medicines', medicineRoutes);
app.use('/api/auth', authRoutes); // Use the new authentication routes

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
