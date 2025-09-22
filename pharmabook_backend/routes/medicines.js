const express = require('express');
const router = express.Router();
const Medicine = require('../models/Medicine');
const auth = require('../middleware/auth');

// @route   GET /api/medicines
// @desc    Get all medicines for the authenticated user
router.get('/', auth, async (req, res) => {
  try {
    // --- DEBUGGING LOGS START ---
    console.log('--- Fetching Medicines ---');
    if (req.user && req.user.id) {
      console.log('Searching for medicines with ownerId:', req.user.id);
    } else {
      console.log('Error: req.user.id is not available in the request.');
      return res.status(401).json({ message: 'Authentication error: User ID not found.' });
    }
    // --- DEBUGGING LOGS END ---

    const medicines = await Medicine.find({ ownerId: req.user.id });
    
    // --- DEBUGGING LOGS START ---
    console.log(`Query found ${medicines.length} medicine(s).`);
    console.log('--------------------------');
    // --- DEBUGGING LOGS END ---

    res.json(medicines);
  } catch (err) {
    console.error('Error fetching medicines:', err.message);
    res.status(500).json({ message: err.message });
  }
});


// @route   POST /api/medicines
// @desc    Add a new medicine product or a new batch to an existing product
router.post('/', auth, async (req, res) => {
  const { name, company, batchNumber, quantity, manufactureDate, expiryDate, variant, price, tabletsPerStrip } = req.body;
  const ownerId = req.user.id;

  try {
    if (!name || !company || !batchNumber || !quantity || !manufactureDate || !expiryDate || price == null || !tabletsPerStrip) {
      return res.status(400).json({ message: 'Please provide all required fields, including tabletsPerStrip.' });
    }

    let medicine = await Medicine.findOne({ name, company, ownerId });

    if (medicine) {
      medicine.batches.push({ batchNumber, quantity, manufactureDate, expiryDate, variant, price, tabletsPerStrip });
      await medicine.save();
      return res.status(201).json(medicine);
    } else {
      const newMedicine = new Medicine({
        name,
        company,
        batches: [{ batchNumber, quantity, manufactureDate, expiryDate, variant, price, tabletsPerStrip }],
        ownerId,
      });
      await newMedicine.save();
      return res.status(201).json(newMedicine);
    }
  } catch (err) {
    console.error('Error adding medicine:', err.message);
    return res.status(500).json({ message: `Failed to add medicine. Server error: ${err.message}` });
  }
});


// --- ALL OTHER ROUTES REMAIN THE SAME ---

// @route   PUT /api/medicines/:medicineId/:batchNumber
router.put('/:medicineId/:batchNumber', auth, async (req, res) => {
  try {
    const { quantity } = req.body;
    const medicine = await Medicine.findOneAndUpdate(
      { _id: req.params.medicineId, ownerId: req.user.id, 'batches.batchNumber': req.params.batchNumber },
      { '$set': { 'batches.$.quantity': quantity } },
      { new: true }
    );

    if (!medicine) {
      return res.status(404).json({ message: 'Medicine or batch not found.' });
    }
    res.json(medicine);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   DELETE /api/medicines/:medicineId/:batchNumber
router.delete('/:medicineId/:batchNumber', auth, async (req, res) => {
  try {
    const medicine = await Medicine.findById(req.params.medicineId);

    if (!medicine || medicine.ownerId.toString() !== req.user.id) {
      return res.status(404).json({ message: 'Medicine not found.' });
    }

    medicine.batches = medicine.batches.filter(
      (batch) => batch.batchNumber !== req.params.batchNumber
    );

    await medicine.save();
    res.json({ message: 'Batch deleted successfully.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   GET api/medicines/expiring
router.get('/expiring', auth, async (req, res) => {
  try {
    const today = new Date();
    const nextMonth = new Date(today.getFullYear(), today.getMonth() + 1, today.getDate());

    const medicines = await Medicine.find({
      ownerId: req.user.id,
      'batches.expiryDate': { $gte: today, $lte: nextMonth },
    });
    res.json(medicines);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   DELETE /api/medicines/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const medicine = await Medicine.findOneAndDelete({
      _id: req.params.id,
      ownerId: req.user.id
    });

    if (!medicine) {
      return res.status(404).json({ msg: 'Medicine not found' });
    }

    res.json({ msg: 'Medicine removed' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;