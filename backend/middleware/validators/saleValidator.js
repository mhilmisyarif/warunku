// middleware/validators/saleValidator.js
const { body } = require('express-validator');

exports.validateCreateSale = [
    body('items').isArray({ min: 1 }).withMessage('At least one item is required.'),
    body('items.*.product').isMongoId().withMessage('Invalid Product ID format in items.'),
    body('items.*.unitLabel').notEmpty().withMessage('Unit label is required for each item.').trim(),
    body('items.*.quantity').isFloat({ gt: 0 }).withMessage('Item quantity must be a positive number.'),
    body('amountReceived')
        .optional({ values: 'null' })
        .isFloat({ min: 0 }).withMessage('Amount received must be zero or more.'),
    body('paymentMethod').optional().isString().trim(),
    body('notes').optional().isString().trim(),
];
