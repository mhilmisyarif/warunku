// models/Sale.js — a paid-on-the-spot (cash) sale from the cart.
const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const saleItemSchema = new Schema({
    product: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
    productName: { type: String, required: true }, // denormalized
    unitLabel: { type: String, required: true },
    quantity: { type: Number, required: true, min: [0.0001, 'Quantity must be positive.'] },
    price: { type: Number, required: true, min: 0 },
    totalPrice: { type: Number, required: true, min: 0 },
});

const saleSchema = new Schema(
    {
        items: {
            type: [saleItemSchema],
            validate: [(v) => Array.isArray(v) && v.length > 0, 'At least one item is required.'],
        },
        totalAmount: { type: Number, required: true, min: 0 },
        // Cash handed over; the app shows the change. Optional.
        amountReceived: { type: Number, min: 0 },
        paymentMethod: { type: String, trim: true, default: 'Tunai' },
        notes: { type: String, trim: true },
        saleDate: { type: Date, default: Date.now, index: true },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Sale', saleSchema);
