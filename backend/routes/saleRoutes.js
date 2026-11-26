// routes/saleRoutes.js
const express = require('express');
const { validationResult } = require('express-validator');
const { createSale, getSales } = require('../controllers/saleController');
const { validateCreateSale } = require('../middleware/validators/saleValidator');

const router = express.Router();

const handleValidationErrors = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    next();
};

router.route('/')
    .get(getSales)
    .post(validateCreateSale, handleValidationErrors, createSale);

module.exports = router;
