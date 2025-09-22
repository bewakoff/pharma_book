const express = require('express');
const router = express.Router();
const Medicine = require('../models/Medicine');
const auth = require('../middleware/auth');

// Add a new medicine or batch
router.post('/', auth, async (req, res) => {
  const { 
    name, company, batchNumber, quantity, manufactureDate, expiryDate, 
    variant, price, isStripBased, tabletsPerStrip 
  } = req.body;
  const ownerId = req.user.id;

  try {
    if (req.user.role !== 'owner') {
      return res.status(403).json({ message: 'Access denied: Only owners can add medicines.' });
    }

    if (!name || !company || !batchNumber || !quantity || !manufactureDate || !expiryDate || price == null) {
      return res.status(400).json({ message: 'Please provide all required fields.' });
    }

    const stripCount = isStripBased ? tabletsPerStrip : 0;

    let medicine = await Medicine.findOne({ name, company, ownerId });

    if (medicine) {
      medicine.batches.push({
        batchNumber,
        quantity,
        manufactureDate,
        expiryDate,
        variant,
        price,
        isStripBased: !!isStripBased,
        tabletsPerStrip: stripCount,
      });
      await medicine.save();
      return res.status(201).json(medicine);
    } else {
      const newMedicine = new Medicine({
        name,
        company,
        ownerId,
        batches: [{
          batchNumber,
          quantity,
          manufactureDate,
          expiryDate,
          variant,
          price,
          isStripBased: !!isStripBased,
          tabletsPerStrip: stripCount,
        }],
      });
      await newMedicine.save();
      return res.status(201).json(newMedicine);
    }

  } catch (err) {
    console.error('Error adding medicine:', err.message);
    return res.status(500).json({ message: `Failed to add medicine. Server error: ${err.message}` });
  }
});

// Other routes like GET, PUT, DELETE can remain same as before
// @route   PUT /api/medicines/:medicineId/:batchNumber
// @desc    Update a specific batch within a medicine (supports strip-based fields)
// @access  Private
router.put('/:medicineId/:batchNumber', auth, async (req, res) => {
  try {
    const { quantity, price, variant, isStripBased, tabletsPerStrip } = req.body;

    const updateFields = {};
    if (quantity !== undefined) updateFields['batches.$.quantity'] = quantity;
    if (price !== undefined) updateFields['batches.$.price'] = price;
    if (variant !== undefined) updateFields['batches.$.variant'] = variant;
    if (isStripBased !== undefined) updateFields['batches.$.isStripBased'] = isStripBased;
    if (tabletsPerStrip !== undefined) updateFields['batches.$.tabletsPerStrip'] = tabletsPerStrip;

    const medicine = await Medicine.findOneAndUpdate(
      { _id: req.params.medicineId, ownerId: req.user.id, 'batches.batchNumber': req.params.batchNumber },
      { $set: updateFields },
      { new: true }
    );

    if (!medicine) {
      return res.status(404).json({ message: 'Medicine or batch not found.' });
    }

    res.json(medicine);
  } catch (err) {
    console.error('Error updating batch:', err.message);
    res.status(500).json({ message: err.message });
  }
});





module.exports = router;
