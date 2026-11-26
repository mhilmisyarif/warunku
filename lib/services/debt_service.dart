import '../models/debt_record.dart';
import 'api_client.dart';

class DebtService {
  DebtService(this._api);

  final ApiClient _api;

  static const pageSize = 10;

  /// Lists debts, optionally for one customer and/or one status.
  Future<PaginatedDebtRecordsResponse> getDebtRecords({
    String? customerId,
    DebtStatus? status,
    int page = 1,
  }) async {
    final path = customerId != null ? '/customers/$customerId/debts' : '/debts';
    final data = await _api.get(
      path,
      query: {
        'status': status?.apiValue ?? '',
        'page': '$page',
        'limit': '$pageSize',
      },
    );
    return PaginatedDebtRecordsResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<DebtRecord> getDebtRecordById(String id) async =>
      DebtRecord.fromJson(await _api.get('/debts/$id'));

  Future<DebtRecord> createDebtRecord(DebtRecord debtRecord) async =>
      DebtRecord.fromJson(await _api.post('/debts', debtRecord.toJson()));

  Future<DebtRecord> addPayment(String debtId, PaymentEntry payment) async =>
      DebtRecord.fromJson(
        await _api.put('/debts/$debtId', {'newPayment': payment.toJson()}),
      );
}
