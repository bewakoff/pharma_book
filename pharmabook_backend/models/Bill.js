const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const billItemSchema = new Schema({
  medicineId: { type: Schema.Types.ObjectId, ref: 'Medicine', required: true },
  medicineName: { type: String, required: true },
  batchNumber: { type: String, required: true },
  quantity: { type: Number, required: true }, // total tablets
  price: { type: Number, required: true }, // total price for this item
  strips: { type: Number, required: true },  // ✅ strips sold
  tablets: { type: Number, required: true }  // ✅ leftover tablets sold
});

const billSchema = new Schema({
  ownerId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  customerName: { type: String, required: true },
  totalAmount: { type: Number, required: true },
  items: [billItemSchema],
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Bill', billSchema);
