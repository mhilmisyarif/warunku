import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts(); // Make sure it has a const constructor
}

class SearchProducts extends ProductEvent {
  final String query;
  const SearchProducts(this.query);

  @override
  List<Object> get props => [query];
}

// Add other product events here if you have them (e.g., AddProduct, UpdateProduct)
// class AddProductEvent extends ProductEvent {
//   final Product product;
//   const AddProductEvent(this.product);
//   @override
//   List<Object> get props => [product];
// }
