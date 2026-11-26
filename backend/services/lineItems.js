// services/lineItems.js
// Shared by sales and debts: turns client line items into priced lines
// against the current product data, checks stock, and deducts it.
const Product = require('../models/Product');

const httpError = (statusCode, message) =>
    Object.assign(new Error(message), { statusCode });

/**
 * Throws 400 when a stock-tracked unit has less on hand than the lines ask
 * for. Quantities of repeated product+unit lines are summed. Pure: no DB.
 * @param {{product: {_id, name}, unit: {label, stock}, quantity: number}[]} lines
 */
function checkStock(lines) {
    const needed = new Map();
    for (const line of lines) {
        if (line.unit.stock == null) continue; // not tracked
        const key = `${line.product._id}:${line.unit.label}`;
        const entry = needed.get(key) || { line, quantity: 0 };
        entry.quantity += line.quantity;
        needed.set(key, entry);
    }
    for (const { line, quantity } of needed.values()) {
        if (quantity > line.unit.stock) {
            throw httpError(
                400,
                `Stok ${line.product.name} (${line.unit.label}) tidak cukup: tersisa ${line.unit.stock}.`
            );
        }
    }
}

/**
 * Loads each item's product and unit and prices it.
 * @param rawItems  [{product, unitLabel, quantity, ...}] from the request
 * @param priceOf   optional raw => client price; when it returns undefined
 *                  (or is omitted) the unit's current selling price is used.
 */
async function resolveItems(rawItems, priceOf = () => undefined) {
    const lines = [];
    for (const raw of rawItems) {
        const product = await Product.findById(raw.product);
        if (!product) throw httpError(404, `Product with ID ${raw.product} not found.`);

        const unit = product.units.find(
            (u) => u.label.toLowerCase() === String(raw.unitLabel).toLowerCase()
        );
        if (!unit) {
            throw httpError(400, `Unit '${raw.unitLabel}' not found for product '${product.name}'.`);
        }

        const price = priceOf(raw) ?? unit.sellingPrice;
        if (price === undefined || price < 0) {
            throw httpError(400, `Invalid price for unit '${unit.label}' of product '${product.name}'.`);
        }

        const quantity = Number(raw.quantity);
        lines.push({ product, unit, quantity, price, totalPrice: quantity * price });
    }
    checkStock(lines);
    return lines;
}

/** Subtracts sold quantities from tracked units. Call after the record is saved. */
async function deductStock(lines) {
    // shortcut: check-then-decrement is not atomic; two simultaneous sales of
    // the last item can both pass. Fine for one shop; use a transaction or a
    // conditional update if several cashiers sell at once.
    for (const { product, unit, quantity } of lines) {
        if (unit.stock == null) continue;
        await Product.updateOne(
            { _id: product._id },
            { $inc: { 'units.$[u].stock': -quantity } },
            { arrayFilters: [{ 'u.label': unit.label }] }
        );
    }
}

module.exports = { checkStock, resolveItems, deductStock, httpError };
