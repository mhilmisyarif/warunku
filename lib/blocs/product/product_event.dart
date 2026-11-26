part of 'product_bloc.dart';

sealed class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the product list, filtered by [query] (empty = all products).
class LoadProducts extends ProductEvent {
  final String query;
  const LoadProducts({this.query = ''});

  @override
  List<Object?> get props => [query];
}

/// Creates or updates [product] (update when it has an id). When
/// [imageFilePath] is set, the image is uploaded first.
class SaveProduct extends ProductEvent {
  final Product product;
  final String? imageFilePath;
  const SaveProduct(this.product, {this.imageFilePath});

  @override
  List<Object?> get props => [product, imageFilePath];
}

/// Reloads the list with the current search, e.g. after stock changed.
class RefreshProducts extends ProductEvent {
  const RefreshProducts();
}

class DeleteProduct extends ProductEvent {
  final String id;
  const DeleteProduct(this.id);

  @override
  List<Object?> get props => [id];
}
