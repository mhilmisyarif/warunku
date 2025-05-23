import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class ProductRepository {
  final String baseUrl;

  ProductRepository({required this.baseUrl});

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    return (jsonDecode(response.body) as List)
        .map((e) => Product.fromJson(e))
        .toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products?search=$query'),
    );
    return (jsonDecode(response.body) as List)
        .map((e) => Product.fromJson(e))
        .toList();
  }
}
