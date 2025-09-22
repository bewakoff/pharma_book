const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Bill = require('../models/Bill');
const Medicine = require('../models/Medicine');
const mongoose = require('mongoose');

router.post('/', auth, async (req, res) => {
  const { customerName, items } = req.body;
  const ownerId = req.user.id;

  if (!customerName || !items || items.length === 0) {
    return res.status(400).json({ msg: 'Please provide all required bill information.' });
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    let totalAmount = 0;
    const billItems = [];

    for (const item of items) {
      const medicine = await Medicine.findById(item.medicineId).session(session);
      if (!medicine) throw new Error(`Medicine ${item.medicineName} not found.`);

      const batch = medicine.batches.find(b => b.batchNumber === item.batchNumber);
      if (!batch) throw new Error(`Batch ${item.batchNumber} not found for ${medicine.name}.`);

      const requestedTablets = item.quantity; // quantity always in tablets
      if (batch.quantity < requestedTablets) {
        throw new Error(`Not enough stock for ${medicine.name}, Batch ${batch.batchNumber}.`);
      }

      // Calculate price
      const pricePerTablet = batch.isStripBased ? batch.price / batch.tabletsPerStrip : batch.price;
      const itemAmount = pricePerTablet * requestedTablets;
      totalAmount += itemAmount;

      // Deduct stock
      batch.quantity -= requestedTablets;
      await medicine.save({ session });

      const strips = batch.isStripBased ? Math.floor(requestedTablets / batch.tabletsPerStrip) : 0;
      const leftoverTablets = batch.isStripBased ? requestedTablets % batch.tabletsPerStrip : requestedTablets;

      billItems.push({
        medicineId: medicine._id,
        medicineName: medicine.name,
        batchNumber: batch.batchNumber,
        quantity: requestedTablets,
        price: itemAmount,
        strips,
        leftoverTablets,
      });
    }

    const newBill = new Bill({
      ownerId,
      customerName,
      totalAmount,
      items: billItems,
    });

    await newBill.save({ session });
    await session.commitTransaction();
    res.status(201).json(newBill);

  } catch (error) {
    await session.abortTransaction();
    console.error(error.message);
    res.status(500).json({ msg: 'Server error', error: error.message });
  } finally {
    session.endSession();
  }
});

module.exports = router;
