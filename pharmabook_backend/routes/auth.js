const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const auth = require('../middleware/auth'); // Import auth middleware

// @route   POST /api/auth/signup
// @desc    Register a new user
router.post('/signup', async (req, res) => {
  try {
    const { email, password, enterpriseName } = req.body;

    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists.' });
    }

    // Create a new user with the default role 'worker'
    user = new User({
      email,
      password,
      enterpriseName,
    });

    // Password is automatically hashed in the pre-save hook
    await user.save();

    res.status(201).json({ message: 'User registered successfully.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   POST /api/auth/login
// @desc    Authenticate user and get token
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials.' });
    }

    // Compare passwords
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials.' });
    }

    // Generate JWT
    const token = jwt.sign(
      { id: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.json({ token, userId: user._id, role: user.role });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   POST /api/auth/forgot-password
// @desc    Handle forgot password logic (send reset link)
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'No user found with that email.' });
    }
    
    // In a real application, you would generate a unique token,
    // save it to the user in the database, and send an email
    // with a link like 'your-app/reset-password?token=<unique-token>'
    
    res.status(200).json({ message: 'Password reset link sent to your email.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   PUT /api/auth/update-role/:id
// @desc    Update a user's role (for owners only)
router.put('/update-role/:id', auth, async (req, res) => {
  try {
    // Check if the authenticated user is an owner
    if (req.user.role !== 'owner') {
      return res.status(403).json({ message: 'Access denied. Only owners can update roles.' });
    }
    
    // Find the user to update and ensure they are not trying to change their own role
    if (req.user.id === req.params.id) {
        return res.status(403).json({ message: 'You cannot change your own role.' });
    }

    const { role } = req.body;
    const updatedUser = await User.findByIdAndUpdate(
        req.params.id,
        { role },
        { new: true, runValidators: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found.' });
    }

    res.json({ message: `User role updated to ${updatedUser.role}` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
