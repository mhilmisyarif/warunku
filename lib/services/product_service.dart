// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart'; // Your existing product model
import '../config/api_constants.dart';

class ProductService {
  final String _productsUrl = '${ApiConstants.baseUrl}/products';
  final String _uploadUrl =
      '${ApiConstants.baseUrl}/products/upload'; // Assuming upload is nested or separate

  // Note: Your original api_services.dart ProductService didn't have pagination or search for getAllProducts.
  // You might want to add that capability here if your backend supports it for products.
  Future<List<Product>> getAllProducts({String searchTerm = ''}) async {
    try {
      // Adjust URL if your backend product search is different
      final Uri uri = Uri.parse('$_productsUrl?search=$searchTerm');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to load products: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in getAllProducts: $e');
      throw Exception('Failed to connect or process product data: $e');
    }
  }

  Future<Product> addProduct(Product product) async {
    try {
      // If imagePath is handled by a separate upload step, product.toJson() might not send it directly here.
      // Or, if imagePath is just a URL string, it's fine.
      final response = await http.post(
        Uri.parse(_productsUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        return Product.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        print('Error adding product: ${response.body}');
        throw Exception(
          'Failed to add product: ${response.statusCode} ${errorData['message'] ?? (errorData['errors'] != null ? (errorData['errors'] as List).map((e) => e['msg']).join(', ') : response.reasonPhrase)}',
        );
      }
    } catch (e) {
      print('Error in addProduct: $e');
      throw Exception('Failed to connect or save product data: $e');
    }
  }

  Future<Product> updateProduct(String id, Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$_productsUrl/$id'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Product not found for update');
      } else {
        final errorData = json.decode(response.body);
        print('Error updating product: ${response.body}');
        throw Exception(
          'Failed to update product: ${response.statusCode} ${errorData['message'] ?? (errorData['errors'] != null ? (errorData['errors'] as List).map((e) => e['msg']).join(', ') : response.reasonPhrase)}',
        );
      }
    } catch (e) {
      print('Error in updateProduct: $e');
      throw Exception('Failed to connect or update product data: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_productsUrl/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Product not found for deletion');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to delete product: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in deleteProduct: $e');
      throw Exception('Failed to connect or delete product data: $e');
    }
  }

  // Image upload - this was not in your original ProductService, but was in ProductFormScreen
  // The backend has POST /api/products/upload
  Future<String> uploadProductImage(String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['imagePath']
            as String; // Ensure backend returns { "imagePath": "..." }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to upload image: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in uploadProductImage: $e');
      throw Exception('Failed to connect or upload image: $e');
    }
  }
}
