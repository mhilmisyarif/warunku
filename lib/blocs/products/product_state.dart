import 'package:equatable/equatable.dart';
import '../../models/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {
  // Optional: A flag to differentiate general list loading vs. operation loading
  final bool isOperating;
  const ProductLoading({this.isOperating = false});

  @override
  List<Object?> get props => [isOperating];
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  const ProductLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

// State for successful CUD operations
class ProductOperationSuccess extends ProductState {
  final String message;
  final Product?
  product; // Optionally return the product that was added/updated
  const ProductOperationSuccess(this.message, {this.product});

  @override
  List<Object?> get props => [message, product];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
