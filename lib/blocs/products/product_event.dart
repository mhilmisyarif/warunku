import 'package:equatable/equatable.dart';
import '../../models/product.dart'; // Your Product model

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final String? query; // Keep this if LoadProducts can sometimes have a query
  const LoadProducts({this.query});

  @override
  List<Object?> get props => [query];
}

class SearchProducts extends ProductEvent {
  final String query;
  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

// Event for adding a product
class AddProductEvent extends ProductEvent {
  final Product product;
  const AddProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

// Event for updating a product (if this form will also handle edits)
class UpdateProductEvent extends ProductEvent {
  final String productId;
  final Product product;
  const UpdateProductEvent(this.productId, this.product);

  @override
  List<Object?> get props => [productId, product];
}

// Add DeleteProductEvent if needed
