const express = require('express');
const router = express.Router();
const Medicine = require('../models/Medicine');
const auth = require('../middleware/auth');

// @route   GET /api/medicines
// @desc    Get all medicines for the authenticated user
router.get('/', auth, async (req, res) => {
  try {
    const medicines = await Medicine.find({ ownerId: req.user.id });
    res.json(medicines);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @route   POST /api/medicines
// @desc    Add a new medicine product with its first batch
router.post('/', auth, async (req, res) => {
  const { name, company, batchNumber, quantity, manufactureDate, expiryDate, variant, price } = req.body;
  const ownerId = req.user.id;

  // Check if a medicine with the same name and company already exists
  let medicine = await Medicine.findOne({ name, company, ownerId });

  if (medicine) {
    // If it exists, add the new batch to the existing medicine
    medicine.batches.push({ batchNumber, quantity, manufactureDate, expiryDate, variant, price });
    try {
      const updatedMedicine = await medicine.save();
      res.status(201).json(updatedMedicine);
    } catch (err) {
      res.status(400).json({ message: err.message });
    }
  } else {
    // If it doesn't exist, create a new medicine document with the batch
    medicine = new Medicine({
      name,
      company,
      batches: [{ batchNumber, quantity, manufactureDate, expiryDate, variant, price }],
      ownerId,
    });
    try {
      const newMedicine = await medicine.save();
      res.status(201).json(newMedicine);
    } catch (err) {
      res.status(400).json({ message: err.message });
    }
  }
});

// @route   PUT /api/medicines/:id
// @desc    Update a specific batch within a medicine
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

// @route   DELETE /api/medicines/:id
// @desc    Delete a specific batch within a medicine
router.delete('/:medicineId/:batchNumber', auth, async (req, res) => {
  try {
    const medicine = await Medicine.findById(req.params.medicineId);

    if (!medicine || medicine.ownerId.toString() !== req.user.id) {
        return res.status(404).json({ message: 'Medicine not found.' });
    }

    // Remove the batch from the batches array
    const initialBatchCount = medicine.batches.length;
    medicine.batches = medicine.batches.filter(
        (batch) => batch.batchNumber !== req.params.batchNumber
    );

    if (medicine.batches.length === initialBatchCount) {
        return res.status(404).json({ message: 'Batch not found.' });
    }

    await medicine.save();
    res.json({ message: 'Batch deleted successfully.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
