const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// @route   POST api/auth/signup
// @desc    Register a new worker user
// @access  Public
router.post('/signup', async (req, res) => {
  const { email, password, enterpriseName } = req.body;

  if (!email || !password || !enterpriseName) {
    return res.status(400).json({ message: 'Please enter all fields' });
  }

  try {
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    user = new User({
      email,
      password, // hashed in pre-save hook
      enterpriseName,
      role: 'worker', // 👈 default worker role
    });

    await user.save();

    res.status(201).json({ message: 'Worker registered successfully' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// @route   POST api/auth/signup-owner
// @desc    Register a new owner account
// @access  Public
router.post('/signup-owner', async (req, res) => {
  const { email, password, enterpriseName } = req.body;

  if (!email || !password || !enterpriseName) {
    return res.status(400).json({ message: 'Please enter all fields' });
  }

  try {
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    user = new User({
      email,
      password,
      enterpriseName,
      role: 'owner', // 👈 mark as owner
    });

    await user.save();

    res.status(201).json({
      message: 'Owner registered successfully',
      ownerId: user._id, // 👈 return ownerId for medicines
      email: user.email,
      enterpriseName: user.enterpriseName,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// @route   POST api/auth/login
// @desc    Authenticate user & get token
// @access  Public
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Please enter all fields' });
  }

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const payload = { user: { id: user.id, role: user.role } };

    jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '5h' }, (err, token) => {
      if (err) throw err;

      res.json({
        token,
        userId: user.id,
        email: user.email,
        role: user.role,
        enterpriseName: user.enterpriseName || '',
      });
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// @route   GET api/auth/user/:id
// @desc    Get user by ID
router.get('/user/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({
      id: user.id,
      email: user.email,
      name: user.name || '',
      role: user.role,
      enterpriseName: user.enterpriseName,
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
