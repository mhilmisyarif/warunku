// controllers/debtController.js
const DebtRecord = require('../models/DebtRecord');
const Customer = require('../models/Customer');
const { resolveItems, deductStock } = require('../services/lineItems');
const asyncHandler = require('express-async-handler');
const { validationResult } = require('express-validator');
const mongoose = require('mongoose');


// @desc    Create a new debt record
// @route   POST /api/debts
// @access  Private (should be protected)
exports.createDebtRecord = asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const { customer: customerId, items: rawItems, debtDate, dueDate, notes, amountPaid } = req.body;

    // Verify customer exists
    const customer = await Customer.findById(customerId);
    if (!customer) {
        res.status(404);
        throw new Error('Customer not found.');
    }

    // Debts may carry the price agreed at the time; otherwise the current price.
    const lines = await resolveItems(rawItems, (raw) => raw.priceAtTimeOfDebt);
    const processedItems = lines.map(({ product, unit, quantity, price, totalPrice }) => ({
        product: product._id,
        productName: product.name, // Denormalized product name
        unitLabel: unit.label,
        quantity,
        priceAtTimeOfDebt: price,
        totalPrice,
    }));
    const calculatedTotalAmount = processedItems.reduce((sum, item) => sum + item.totalPrice, 0);

    const initialPayment = Number(amountPaid) || 0;
    if (initialPayment > calculatedTotalAmount) {
        res.status(400);
        throw new Error('Initial payment cannot exceed the total amount.');
    }

    const debtRecord = new DebtRecord({
        customer: customerId,
        items: processedItems,
        totalAmount: calculatedTotalAmount, // Use server-calculated total
        debtDate: debtDate || Date.now(),
        dueDate,
        notes,
        // The pre-save hook derives amountPaid from paymentHistory, so an
        // initial payment must be recorded as a history entry to survive.
        paymentHistory: initialPayment > 0
            ? [{ amount: initialPayment, paymentDate: debtDate || Date.now(), method: 'Initial payment' }]
            : [],
    });

    // The pre-save hook in DebtRecord model will handle status and re-calculate totalAmount.
    const createdDebtRecord = await debtRecord.save();
    await deductStock(lines);
    res.status(201).json(createdDebtRecord);
});


// @desc    Get all debt records (with filters)
// @route   GET /api/debts
// @access  Private (should be protected)
exports.getDebtRecords = asyncHandler(async (req, res) => {
    const { customerId, status, startDate, endDate } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = {};
    if (customerId) {
        if (!mongoose.Types.ObjectId.isValid(customerId)) {
            res.status(400); throw new Error('Invalid customer ID format for filter.');
        }
        query.customer = customerId;
    }
    if (status) {
        query.status = status.toUpperCase();
    }
    if (startDate) {
        query.debtDate = { ...query.debtDate, $gte: new Date(startDate) };
    }
    if (endDate) {
        // Add 1 day to endDate to include the whole day
        let endOfDay = new Date(endDate);
        endOfDay.setDate(endOfDay.getDate() + 1);
        query.debtDate = { ...query.debtDate, $lt: endOfDay };
    }

    const debtRecords = await DebtRecord.find(query)
        .populate('customer', 'name phoneNumber') // Populate customer details
        .populate('items.product', 'name category') // Populate basic product info in items
        .sort({ debtDate: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit);

    const totalDebtRecords = await DebtRecord.countDocuments(query);

    res.json({
        debtRecords,
        currentPage: page,
        totalPages: Math.ceil(totalDebtRecords / limit),
        totalDebtRecords,
    });
});

// @desc    Get debt records for a specific customer
// @route   GET /api/customers/:customerId/debts
// @access  Private
exports.getDebtsByCustomer = asyncHandler(async (req, res) => {
    const errors = validationResult(req); // For param validation
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const customerId = req.params.customerId;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const customer = await Customer.findById(customerId);
    if (!customer) {
        res.status(404); throw new Error('Customer not found.');
    }

    const query = { customer: customerId };
    const { status, startDate, endDate } = req.query; // Additional filters
    if (status) query.status = status.toUpperCase();
    if (startDate) query.debtDate = { ...query.debtDate, $gte: new Date(startDate) };
    if (endDate) {
        let endOfDay = new Date(endDate);
        endOfDay.setDate(endOfDay.getDate() + 1);
        query.debtDate = { ...query.debtDate, $lt: endOfDay };
    }


    const debtRecords = await DebtRecord.find(query)
        .populate('items.product', 'name category')
        .sort({ debtDate: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit);

    const totalDebtRecords = await DebtRecord.countDocuments(query);

    res.json({
        customerName: customer.name, // Optional: return customer name too
        debtRecords,
        currentPage: page,
        totalPages: Math.ceil(totalDebtRecords / limit),
        totalDebtRecords,
    });
});


// @desc    Get a single debt record by ID
// @route   GET /api/debts/:id
// @access  Private (should be protected)
exports.getDebtRecordById = asyncHandler(async (req, res) => {
    const errors = validationResult(req); // For param validation
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const debtRecord = await DebtRecord.findById(req.params.id)
        .populate('customer', 'name phoneNumber address')
        .populate('items.product', 'name category imagePath units'); // More product details

    if (debtRecord) {
        res.json(debtRecord);
    } else {
        res.status(404);
        throw new Error('Debt record not found');
    }
});

// @desc    Update a debt record (e.g., for payments)
// @route   PUT /api/debts/:id
// @access  Private (should be protected)
exports.updateDebtRecord = asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const debtRecord = await DebtRecord.findById(req.params.id);

    if (!debtRecord) {
        res.status(404);
        throw new Error('Debt record not found');
    }

    const { newPayment, notes, dueDate } = req.body; // newPayment would be an object like { amount: 100, method: 'Cash', paymentDate: '...', notes: '...' }

    if (newPayment && newPayment.amount > 0) {
        // Basic validation for newPayment object
        if (typeof newPayment.amount !== 'number' || newPayment.amount <= 0) {
            res.status(400); throw new Error('Invalid payment amount.');
        }
        const paymentDate = newPayment.paymentDate ? new Date(newPayment.paymentDate) : new Date();
        if (isNaN(paymentDate)) {
            res.status(400); throw new Error('Invalid payment date.');
        }

        debtRecord.paymentHistory.push({
            amount: newPayment.amount,
            paymentDate: paymentDate,
            method: newPayment.method, // Optional
            notes: newPayment.notes    // Optional
        });
    }

    // Update other fields if provided
    if (notes !== undefined) {
        debtRecord.notes = notes;
    }
    if (dueDate !== undefined) {
        debtRecord.dueDate = dueDate;
    }
    // Do NOT directly set debtRecord.amountPaid or debtRecord.status here.
    // Let the pre-save hook handle it.

    const updatedDebtRecord = await debtRecord.save();
    res.json(updatedDebtRecord);
});

// @desc    Delete a debt record
// @route   DELETE /api/debts/:id
// @access  Private (should be protected - use with caution)
// exports.deleteDebtRecord = asyncHandler(async (req, res) => {
//   const errors = validationResult(req); // For param validation
//   if (!errors.isEmpty()) {
//     return res.status(400).json({ errors: errors.array() });
//   }
//   const debtRecord = await DebtRecord.findById(req.params.id);
//   if (debtRecord) {
//     await debtRecord.deleteOne();
//     res.json({ message: 'Debt record removed successfully' });
//   } else {
//     res.status(404);
//     throw new Error('Debt record not found');
//   }
// });
// Generally, deleting financial records isn't a good idea.
// Consider soft delete (e.g., an `isActive: false` flag) or just marking as 'VOID' or similar.