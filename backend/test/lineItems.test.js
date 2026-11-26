const test = require('node:test');
const assert = require('node:assert');
const { checkStock } = require('../services/lineItems');

const rice = { _id: 'p1', name: 'Beras' };
const line = (unit, quantity) => ({ product: rice, unit, quantity });

test('untracked units never block a sale', () => {
    assert.doesNotThrow(() => checkStock([line({ label: 'kg' }, 999)]));
});

test('enough stock passes, exact stock passes', () => {
    assert.doesNotThrow(() => checkStock([line({ label: 'kg', stock: 5 }, 5)]));
});

test('repeated lines are summed against stock', () => {
    const kg = { label: 'kg', stock: 5 };
    assert.throws(() => checkStock([line(kg, 3), line(kg, 3)]), (e) => e.statusCode === 400 && /tersisa 5/.test(e.message));
});

test('zero stock blocks', () => {
    assert.throws(() => checkStock([line({ label: 'kg', stock: 0 }, 1)]));
});
