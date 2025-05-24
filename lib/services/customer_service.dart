// lib/services/customer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../models/debt_record.dart'; // For PaginatedDebtRecordsResponse
import '../config/api_constants.dart'; // Assuming you created this

class CustomerService {
  final String _customersUrl = '${ApiConstants.baseUrl}/customers';

  Future<PaginatedCustomersResponse> getCustomers({
    String searchTerm = '',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Uri uri = Uri.parse(
        '$_customersUrl?search=$searchTerm&page=$page&limit=$limit',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PaginatedCustomersResponse.fromJson(data);
      } else {
        // Consider more specific error handling based on status code
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to load customers: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      // Log error or handle network issues
      print('Error in getCustomers: $e');
      throw Exception('Failed to connect or process customer data: $e');
    }
  }

  Future<Customer> getCustomerById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_customersUrl/$id'));

      if (response.statusCode == 200) {
        return Customer.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Customer not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to load customer: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in getCustomerById: $e');
      throw Exception('Failed to connect or process customer data: $e');
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await http.post(
        Uri.parse(_customersUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(customer.toJson()),
      );

      if (response.statusCode == 201) {
        // 201 Created
        return Customer.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        print('Error creating customer: ${response.body}');
        throw Exception(
          'Failed to create customer: ${response.statusCode} ${errorData['message'] ?? (errorData['errors'] != null ? (errorData['errors'] as List).map((e) => e['msg']).join(', ') : response.reasonPhrase)}',
        );
      }
    } catch (e) {
      print('Error in createCustomer: $e');
      throw Exception('Failed to connect or save customer data: $e');
    }
  }

  Future<Customer> updateCustomer(String id, Customer customer) async {
    try {
      final response = await http.put(
        Uri.parse('$_customersUrl/$id'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(customer.toJson()),
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Customer not found for update');
      } else {
        final errorData = json.decode(response.body);
        print('Error updating customer: ${response.body}');
        throw Exception(
          'Failed to update customer: ${response.statusCode} ${errorData['message'] ?? (errorData['errors'] != null ? (errorData['errors'] as List).map((e) => e['msg']).join(', ') : response.reasonPhrase)}',
        );
      }
    } catch (e) {
      print('Error in updateCustomer: $e');
      throw Exception('Failed to connect or update customer data: $e');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_customersUrl/$id'));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200 OK with message, 204 No Content
        return; // Successfully deleted
      } else if (response.statusCode == 404) {
        throw Exception('Customer not found for deletion');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to delete customer: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in deleteCustomer: $e');
      throw Exception('Failed to connect or delete customer data: $e');
    }
  }

  Future<PaginatedDebtRecordsResponse> getDebtsByCustomerId(
    String customerId, {
    String status = '',
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Construct query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status.isNotEmpty) queryParams['status'] = status;
      if (startDate != null && startDate.isNotEmpty)
        queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty)
        queryParams['endDate'] = endDate;

      final Uri uri = Uri.parse(
        '$_customersUrl/$customerId/debts',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PaginatedDebtRecordsResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Customer or debts not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to load debts for customer: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in getDebtsByCustomerId: $e');
      throw Exception('Failed to connect or process customer debt data: $e');
    }
  }
}
