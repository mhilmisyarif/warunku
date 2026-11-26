import '../models/customer.dart';
import 'api_client.dart';

class CustomerService {
  CustomerService(this._api);

  final ApiClient _api;

  static const pageSize = 10;

  Future<PaginatedCustomersResponse> getCustomers({
    String searchTerm = '',
    int page = 1,
  }) async {
    final data = await _api.get(
      '/customers',
      query: {'search': searchTerm, 'page': '$page', 'limit': '$pageSize'},
    );
    return PaginatedCustomersResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<Customer> createCustomer(Customer customer) async =>
      Customer.fromJson(await _api.post('/customers', customer.toJson()));

  Future<Customer> updateCustomer(String id, Customer customer) async =>
      Customer.fromJson(await _api.put('/customers/$id', customer.toJson()));

  Future<void> deleteCustomer(String id) => _api.delete('/customers/$id');
}
