// lib/services/debt_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/debt_record.dart';
import '../config/api_constants.dart';

class DebtService {
  final String _debtsUrl = '${ApiConstants.baseUrl}/debts';

  Future<DebtRecord> createDebtRecord(DebtRecord debtRecord) async {
    try {
      final response = await http.post(
        Uri.parse(_debtsUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(debtRecord.toJson()), // toJson should send customerId
      );

      if (response.statusCode == 201) {
        // 201 Created
        return DebtRecord.fromJson(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        print('Error creating debt record: ${response.body}');
        throw Exception(
          'Failed to create debt record: ${response.statusCode} ${errorData['message'] ?? (errorData['errors'] != null ? (errorData['errors'] as List).map((e) => e['msg']).join(', ') : response.reasonPhrase)}',
        );
      }
    } catch (e) {
      print('Error in createDebtRecord: $e');
      throw Exception('Failed to connect or save debt data: $e');
    }
  }

  Future<PaginatedDebtRecordsResponse> getDebtRecords({
    String? customerId,
    String status = '',
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (customerId != null && customerId.isNotEmpty)
        queryParams['customerId'] = customerId;
      if (status.isNotEmpty) queryParams['status'] = status;
      if (startDate != null && startDate.isNotEmpty)
        queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty)
        queryParams['endDate'] = endDate;

      final Uri uri = Uri.parse(
        _debtsUrl,
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PaginatedDebtRecordsResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to load debt records: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in getDebtRecords: $e');
      throw Exception('Failed to connect or process debt records: $e');
    }
  }

  Future<DebtRecord> getDebtRecordById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_debtsUrl/$id'));

      if (response.statusCode == 200) {
        return DebtRecord.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Debt record not found');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to load debt record: ${response.statusCode} ${errorData['message'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error in getDebtRecordById: $e');
      throw Exception('Failed to connect or process debt record data: $e');
    }
  }

  // For updating debt, especially payments or status
  Future<DebtRecord> updateDebtRecord(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    // updateData could be {'amountPaid': newAmount, 'status': 'PARTIALLY_PAID'}
    try {
      final response = await http.put(
        Uri.parse('$_debtsUrl/$id'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return DebtRecord.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Debt record not found for update');
      } else {
        final errorData = json.decode(response.body);
        print('Error updating debt record: ${response.body}');
        throw Exception(
          'Failed to update debt record: ${response.statusCode} ${errorData['message'] ?? (errorData['errors'] != null ? (errorData['errors'] as List).map((e) => e['msg']).join(', ') : response.reasonPhrase)}',
        );
      }
    } catch (e) {
      print('Error in updateDebtRecord: $e');
      throw Exception('Failed to connect or update debt record: $e');
    }
  }

  // Deleting debt records might not be common; often they are marked as 'VOID' or similar.
  // If you need delete, uncomment and implement:
  // Future<void> deleteDebtRecord(String id) async { ... }
}
