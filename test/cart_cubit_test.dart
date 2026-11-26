import 'package:flutter_test/flutter_test.dart';
import 'package:warunku/blocs/cart/cart_cubit.dart';
import 'package:warunku/models/product.dart';

void main() {
  const kg = ProductUnit(label: 'kg', sellingPrice: 14000, stock: 2);
  const sack = ProductUnit(label: 'karung', sellingPrice: 300000);
  const rice = Product(
    id: 'p1',
    name: 'Beras',
    category: 'Makanan',
    units: [kg, sack],
  );

  test('adding the same unit twice merges into one line', () {
    final cart = CartCubit();
    expect(cart.add(rice, kg), isTrue);
    expect(cart.add(rice, kg), isTrue);
    expect(cart.state, hasLength(1));
    expect(cart.state.single.quantity, 2);
    expect(cart.total, 28000);
  });

  test('different units of one product are separate lines', () {
    final cart =
        CartCubit()
          ..add(rice, kg)
          ..add(rice, sack);
    expect(cart.state, hasLength(2));
    expect(cart.total, 314000);
  });

  test('tracked stock caps adding and setQuantity; untracked does not', () {
    final cart =
        CartCubit()
          ..add(rice, kg)
          ..add(rice, kg);
    expect(cart.add(rice, kg), isFalse, reason: 'only 2 kg in stock');
    cart.setQuantity(0, 10);
    expect(cart.state.single.quantity, 2);

    cart.add(rice, sack);
    cart.setQuantity(1, 50);
    expect(cart.state[1].quantity, 50);
  });

  test('out-of-stock units cannot be added', () {
    const empty = ProductUnit(label: 'kg', sellingPrice: 1, stock: 0);
    final cart = CartCubit();
    expect(cart.add(rice, empty), isFalse);
    expect(cart.state, isEmpty);
  });

  test('quantity zero removes the line; clear empties the cart', () {
    final cart =
        CartCubit()
          ..add(rice, kg)
          ..add(rice, sack);
    cart.setQuantity(0, 0);
    expect(cart.state.single.unit.label, 'karung');
    cart.clear();
    expect(cart.state, isEmpty);
  });

  test('unit stock and cost round-trip; null fields are omitted', () {
    final unit = ProductUnit.fromJson({
      'label': 'kg',
      'sellingPrice': 14000,
      'purchasePrice': 12000,
      'stock': 3,
    });
    expect(unit.margin, 2000);
    expect(unit.toJson(), {
      'label': 'kg',
      'sellingPrice': 14000.0,
      'purchasePrice': 12000.0,
      'stock': 3.0,
    });
    expect(sack.toJson().keys, ['label', 'sellingPrice']);
  });
}
