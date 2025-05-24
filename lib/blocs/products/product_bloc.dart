// lib/blocs/products/product_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
// No need for Equatable for the BLoC class itself, but for events and states
import '../../models/product.dart';
import '../../services/product_service.dart'; // Ensure this points to your ProductService
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService productService;

  ProductBloc(this.productService) : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        // Call getAllProducts without a specific query, or with a default empty search term
        // The ProductService's getAllProducts method is designed to handle an optional searchTerm.
        final products =
            await productService
                .getAllProducts(); // Or: await productService.getAllProducts(searchTerm: "");
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError('Failed to load products: ${e.toString()}'));
      }
    });

    on<SearchProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        // Use event.query for the SearchProducts event
        final products = await productService.getAllProducts(
          searchTerm: event.query,
        );
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError('Search failed: ${e.toString()}'));
      }
    });

    // TODO: Add handlers for AddProduct, UpdateProduct, DeleteProduct events if they exist
    // Example for AddProduct (assuming you create an AddProductEvent):
    // on<AddProductEvent>((event, emit) async {
    //   emit(ProductLoading()); // Or a specific ProductAdding state
    //   try {
    //     await productService.addProduct(event.product);
    //     // You might want a different success state or to reload products
    //     emit(ProductOperationSuccess("Product added successfully!")); // Example: Create this state
    //     add(LoadProducts()); // Refresh list
    //   } catch (e) {
    //     emit(ProductError("Failed to add product: ${e.toString()}"));
    //   }
    // });
  }
}
