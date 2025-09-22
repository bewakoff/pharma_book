const mongoose = require('mongoose');

const batchSchema = new mongoose.Schema({
  batchNumber: { type: String, required: true },
  manufactureDate: { type: Date, required: true },
  expiryDate: { type: Date, required: true },
  quantity: { type: Number, required: true }, // always total tablets
  variant: { type: String },
  price: { type: Number, required: true }, // price per strip if strip-based
  isStripBased: { type: Boolean, default: false },
  tabletsPerStrip: {
    type: Number,
    required: function () {
      return this.isStripBased;
    },
    default: 0,
  },
});

const medicineSchema = new mongoose.Schema({
  name: { type: String, required: true },
  company: { type: String, required: true },
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  batches: [batchSchema],
});

module.exports = mongoose.model('Medicine', medicineSchema);
