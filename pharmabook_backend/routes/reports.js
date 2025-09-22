const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Medicine = require('../models/Medicine');

// @route   GET api/reports/daily
// @desc    Get daily report (medicines added today)
// @access  Private
router.get('/daily', auth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const medicines = await Medicine.find({
      ownerId: req.user.id,
      'batches.createdAt': { $gte: today }
    });
    res.json(medicines);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET api/reports/weekly
// @desc    Get weekly report (medicines added in the last 7 days)
// @access  Private
router.get('/weekly', auth, async (req, res) => {
  try {
    const today = new Date();
    const lastWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    lastWeek.setHours(0, 0, 0, 0);

    const medicines = await Medicine.find({
      ownerId: req.user.id,
      'batches.createdAt': { $gte: lastWeek }
    });
    res.json(medicines);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET api/reports/monthly
// @desc    Get monthly report (medicines added in the last 30 days)
// @access  Private
router.get('/monthly', auth, async (req, res) => {
  try {
    const today = new Date();
    const lastMonth = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
    lastMonth.setHours(0, 0, 0, 0);

    const medicines = await Medicine.find({
      ownerId: req.user.id,
      'batches.createdAt': { $gte: lastMonth }
    });
    res.json(medicines);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;