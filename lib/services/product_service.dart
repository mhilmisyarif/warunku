import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  ProductService(this._api);

  final ApiClient _api;

  Future<List<Product>> getProducts({String searchTerm = ''}) async {
    final data = await _api.get('/products', query: {'search': searchTerm});
    return (data as List<dynamic>)
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> addProduct(Product product) async =>
      Product.fromJson(await _api.post('/products', product.toJson()));

  Future<Product> updateProduct(Product product) async => Product.fromJson(
    await _api.put('/products/${product.id}', product.toJson()),
  );

  Future<void> deleteProduct(String id) => _api.delete('/products/$id');

  /// Uploads a local image and returns the stored path.
  Future<String> uploadProductImage(String filePath) async {
    final data = await _api.upload('/products/upload', 'image', filePath);
    return (data as Map<String, dynamic>)['imagePath'] as String;
  }
}
