part of 'product_bloc.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

// --- List states: drive the product list. ---

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final String query;
  const ProductLoaded(this.products, {this.query = ''});

  @override
  List<Object?> get props => [products, query];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Operation states: one-off results of save/delete, for listeners. ---

class ProductSaving extends ProductState {}

class ProductOperationSuccess extends ProductState {
  final String message;
  const ProductOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductOperationFailure extends ProductState {
  final String message;
  const ProductOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

extension ProductStateX on ProductState {
  /// Whether this state describes the product list (vs. a save/delete result).
  bool get isListState =>
      this is ProductInitial ||
      this is ProductLoading ||
      this is ProductLoaded ||
      this is ProductError;
}
