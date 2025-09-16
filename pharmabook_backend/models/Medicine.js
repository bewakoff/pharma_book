const mongoose = require('mongoose');

const batchSchema = new mongoose.Schema({
  batchNumber: { type: String, required: true },
  manufactureDate: { type: Date, required: true },
  expiryDate: { type: Date, required: true },
  quantity: { type: Number, required: true },
  variant: { type: String, required: false },
  price: { type: Number, required: true, default: 0 },
});

const medicineSchema = new mongoose.Schema({
  name: { type: String, required: true },
  company: { type: String, required: true },
  batches: [batchSchema], // A single medicine can have multiple batches
  ownerId: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
});

const Medicine = mongoose.model('Medicine', medicineSchema);

module.exports = Medicine;
