// import 'package:http/http.dart' as http; // Remove if ProductService handles http
// import 'dart:convert'; // Remove if ProductService handles json
import '../models/product.dart';
import '../services/product_service.dart'; // <--- IMPORT ProductService

class ProductRepository {
  // final String baseUrl; // This was your old setup
  final ProductService _productService; // <--- INJECT ProductService

  ProductRepository({
    required ProductService productService,
  }) // <--- Update constructor
  : _productService = productService;

  Future<List<Product>> fetchProducts() async {
    // Delegate to ProductService
    return await _productService.getAllProducts();
  }

  Future<List<Product>> searchProducts(String query) async {
    // Delegate to ProductService
    return await _productService.getAllProducts(searchTerm: query);
  }

  // Add other methods (addProduct, updateProduct, deleteProduct) here,
  // delegating to _productService.
  Future<Product> addProduct(Product product) async {
    return await _productService.addProduct(product);
  }

  Future<Product> updateProduct(String id, Product product) async {
    return await _productService.updateProduct(id, product);
  }

  Future<void> deleteProduct(String id) async {
    return await _productService.deleteProduct(id);
  }
}
