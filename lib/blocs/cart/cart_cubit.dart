import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/product.dart';

/// One product+unit in the cart.
class CartLine extends Equatable {
  final Product product;
  final ProductUnit unit;
  final double quantity;

  const CartLine(this.product, this.unit, this.quantity);

  double get subtotal => unit.sellingPrice * quantity;

  bool sameItem(Product p, ProductUnit u) =>
      product.id == p.id && unit.label == u.label;

  /// Whether one more can be added without exceeding tracked stock.
  bool get canIncrement => !unit.tracksStock || quantity + 1 <= unit.stock!;

  @override
  List<Object?> get props => [product.id, unit.label, quantity];
}

/// In-memory shopping cart shared by the product list and checkout.
class CartCubit extends Cubit<List<CartLine>> {
  CartCubit() : super(const []);

  double get total => state.fold(0, (sum, line) => sum + line.subtotal);

  /// Adds one of [unit]. Returns false (and changes nothing) when tracked
  /// stock would be exceeded.
  bool add(Product product, ProductUnit unit) {
    final index = state.indexWhere((l) => l.sameItem(product, unit));
    if (index == -1) {
      if (unit.isOutOfStock) return false;
      emit([...state, CartLine(product, unit, 1)]);
      return true;
    }
    final line = state[index];
    if (!line.canIncrement) return false;
    _replace(index, CartLine(product, unit, line.quantity + 1));
    return true;
  }

  /// Sets the quantity of the line at [index]; zero or less removes it.
  /// Clamped to tracked stock.
  void setQuantity(int index, double quantity) {
    final line = state[index];
    if (quantity <= 0) {
      emit([...state]..removeAt(index));
      return;
    }
    final stock = line.unit.stock;
    final clamped = stock != null && quantity > stock ? stock : quantity;
    _replace(index, CartLine(line.product, line.unit, clamped));
  }

  void clear() => emit(const []);

  void _replace(int index, CartLine line) => emit([...state]..[index] = line);
}
