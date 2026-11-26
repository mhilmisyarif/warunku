// controllers/saleController.js
const Sale = require('../models/Sale');
const asyncHandler = require('express-async-handler');
const { resolveItems, deductStock, httpError } = require('../services/lineItems');

// @desc    Record a cash sale; prices come from the current product data
// @route   POST /api/sales
exports.createSale = asyncHandler(async (req, res) => {
    const { items: rawItems, amountReceived, paymentMethod, notes } = req.body;

    const lines = await resolveItems(rawItems);
    const totalAmount = lines.reduce((sum, line) => sum + line.totalPrice, 0);

    if (amountReceived != null && Number(amountReceived) < totalAmount) {
        throw httpError(400, 'Uang diterima kurang dari total belanja.');
    }

    const sale = await Sale.create({
        items: lines.map(({ product, unit, quantity, price, totalPrice }) => ({
            product: product._id,
            productName: product.name,
            unitLabel: unit.label,
            quantity,
            price,
            totalPrice,
        })),
        totalAmount,
        amountReceived,
        paymentMethod,
        notes,
    });
    await deductStock(lines);
    res.status(201).json(sale);
});

// @desc    List sales, newest first (paginated)
// @route   GET /api/sales?page=&limit=
exports.getSales = asyncHandler(async (req, res) => {
    const page = Math.max(parseInt(req.query.page) || 1, 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit) || 20, 1), 100);

    const [sales, totalSales] = await Promise.all([
        Sale.find().sort({ saleDate: -1 }).skip((page - 1) * limit).limit(limit),
        Sale.countDocuments(),
    ]);

    res.json({
        sales,
        currentPage: page,
        totalPages: Math.ceil(totalSales / limit),
        totalSales,
    });
});
