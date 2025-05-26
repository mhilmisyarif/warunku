import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductService productService;

  ProductBloc(this.productService) : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(const ProductLoading());
      try {
        final products = await productService.getAllProducts(
          searchTerm: event.query ?? "",
        );
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError('Failed to load products: ${e.toString()}'));
      }
    });

    on<SearchProducts>((event, emit) async {
      emit(const ProductLoading());
      try {
        final products = await productService.getAllProducts(
          searchTerm: event.query,
        );
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError('Search failed: ${e.toString()}'));
      }
    });

    on<AddProductEvent>((event, emit) async {
      emit(
        const ProductLoading(isOperating: true),
      ); // Indicate an operation is in progress
      try {
        final newProduct = await productService.addProduct(event.product);
        emit(
          ProductOperationSuccess(
            "Product added successfully!",
            product: newProduct,
          ),
        );
        // Optionally, to refresh the product list immediately:
        // add(const LoadProducts()); // Or manage list update more granularly if possible
      } catch (e) {
        emit(ProductError("Failed to add product: ${e.toString()}"));
      }
    });

    on<UpdateProductEvent>((event, emit) async {
      emit(const ProductLoading(isOperating: true));
      try {
        final updatedProduct = await productService.updateProduct(
          event.productId,
          event.product,
        );
        emit(
          ProductOperationSuccess(
            "Product updated successfully!",
            product: updatedProduct,
          ),
        );
        // Optionally, refresh the list:
        // add(const LoadProducts());
      } catch (e) {
        emit(ProductError("Failed to update product: ${e.toString()}"));
      }
    });
    // Add DeleteProductEvent handler if needed
  }
}
