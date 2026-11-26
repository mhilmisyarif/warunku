import 'customer.dart';

enum DebtStatus {
  unpaid('UNPAID', 'Belum lunas'),
  partiallyPaid('PARTIALLY_PAID', 'Dicicil'),
  paid('PAID', 'Lunas');

  const DebtStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DebtStatus fromApi(String? value) => DebtStatus.values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => DebtStatus.unpaid,
  );
}

class DebtItem {
  final String? id;
  final String productId;
  final String productName;
  final String unitLabel;
  final double quantity;
  final double priceAtTimeOfDebt;
  final double totalPrice;

  const DebtItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.unitLabel,
    required this.quantity,
    required this.priceAtTimeOfDebt,
    required this.totalPrice,
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return DebtItem(
      id: json['_id'] as String?,
      // The backend may send the product id or the populated product.
      productId:
          product is Map
              ? product['_id'] as String? ?? ''
              : product as String? ?? '',
      productName: json['productName'] as String? ?? '',
      unitLabel: json['unitLabel'] as String? ?? '',
      quantity: (json['quantity'] as num).toDouble(),
      priceAtTimeOfDebt: (json['priceAtTimeOfDebt'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'product': productId,
    'productName': productName,
    'unitLabel': unitLabel,
    'quantity': quantity,
    'priceAtTimeOfDebt': priceAtTimeOfDebt,
    'totalPrice': totalPrice,
  };
}

class PaymentEntry {
  final String? id;
  final double amount;
  final DateTime paymentDate;
  final String? method;
  final String? notes;
  final DateTime? recordedAt;

  const PaymentEntry({
    this.id,
    required this.amount,
    required this.paymentDate,
    this.method,
    this.notes,
    this.recordedAt,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
    id: json['_id'] as String?,
    amount: (json['amount'] as num).toDouble(),
    paymentDate: DateTime.parse(json['paymentDate'] as String),
    method: json['method'] as String?,
    notes: json['notes'] as String?,
    recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'paymentDate': paymentDate.toIso8601String(),
    if (method != null) 'method': method,
    if (notes != null) 'notes': notes,
  };
}

class DebtRecord {
  final String? id;
  final String customerId;

  /// Present when the backend populated the customer.
  final Customer? customer;
  final List<DebtItem> items;
  final double totalAmount;
  final double amountPaid;
  final DebtStatus status;
  final List<PaymentEntry> paymentHistory;
  final DateTime debtDate;
  final DateTime? dueDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DebtRecord({
    this.id,
    required this.customerId,
    this.customer,
    required this.items,
    required this.totalAmount,
    this.amountPaid = 0,
    this.status = DebtStatus.unpaid,
    this.paymentHistory = const [],
    required this.debtDate,
    this.dueDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  double get remainingBalance => totalAmount - amountPaid;

  String get customerName => customer?.name ?? 'Pelanggan tidak dikenal';

  factory DebtRecord.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'];
    final customer =
        customerData is Map<String, dynamic>
            ? Customer.fromJson(customerData)
            : null;

    return DebtRecord(
      id: json['_id'] as String?,
      customerId: customer?.id ?? customerData as String? ?? '',
      customer: customer,
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map((e) => DebtItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      status: DebtStatus.fromApi(json['status'] as String?),
      paymentHistory:
          (json['paymentHistory'] as List<dynamic>? ?? [])
              .map((e) => PaymentEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
      debtDate: DateTime.parse(json['debtDate'] as String),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  /// Body for creating a debt. Totals and status are derived by the backend;
  /// [amountPaid] is recorded there as the initial payment.
  Map<String, dynamic> toJson() => {
    'customer': customerId,
    'items': items.map((item) => item.toJson()).toList(),
    'debtDate': debtDate.toIso8601String(),
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    if (amountPaid > 0) 'amountPaid': amountPaid,
  };
}

class PaginatedDebtRecordsResponse {
  final List<DebtRecord> debtRecords;
  final int currentPage;
  final int totalPages;
  final int totalDebtRecords;

  const PaginatedDebtRecordsResponse({
    required this.debtRecords,
    required this.currentPage,
    required this.totalPages,
    required this.totalDebtRecords,
  });

  factory PaginatedDebtRecordsResponse.fromJson(Map<String, dynamic> json) =>
      PaginatedDebtRecordsResponse(
        debtRecords:
            (json['debtRecords'] as List<dynamic>? ?? [])
                .map((e) => DebtRecord.fromJson(e as Map<String, dynamic>))
                .toList(),
        currentPage: json['currentPage'] as int? ?? 1,
        totalPages: json['totalPages'] as int? ?? 1,
        totalDebtRecords: json['totalDebtRecords'] as int? ?? 0,
      );
}
