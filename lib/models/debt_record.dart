import './customer.dart'; // Assuming customer.dart is in the same directory
import './product.dart'; // Your existing product model

class DebtItem {
  final String? id; // Sub-document ID from MongoDB
  final String productId; // Keep as String to match backend ObjectId string
  final String productName;
  final String unitLabel;
  final double quantity;
  final double priceAtTimeOfDebt;
  final double totalPrice;

  DebtItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.unitLabel,
    required this.quantity,
    required this.priceAtTimeOfDebt,
    required this.totalPrice,
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    return DebtItem(
      id: json['_id'] as String?,
      productId:
          json['product'] is String
              ? json['product']
              : (json['product'] as Map<String, dynamic>)['_id']
                  as String, // Handle populated vs. ID
      productName: json['productName'] as String,
      unitLabel: json['unitLabel'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      priceAtTimeOfDebt: (json['priceAtTimeOfDebt'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id is usually not sent for sub-documents when creating/updating parent
      'product': productId,
      'productName': productName,
      'unitLabel': unitLabel,
      'quantity': quantity,
      'priceAtTimeOfDebt': priceAtTimeOfDebt,
      'totalPrice': totalPrice, // Backend might recalculate this
    };
  }
}

class PaymentEntry {
  final String? id; // Optional: if your backend sends _id for sub-documents
  final double amount;
  final DateTime paymentDate;
  final String? method;
  final String? notes;
  final DateTime? recordedAt; // From backend's paymentEntrySchema timestamps

  PaymentEntry({
    this.id,
    required this.amount,
    required this.paymentDate,
    this.method,
    this.notes,
    this.recordedAt,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      id: json['_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      method: json['method'] as String?,
      notes: json['notes'] as String?,
      recordedAt:
          json['recordedAt'] != null
              ? DateTime.parse(json['recordedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    // Primarily for sending a new payment to the backend
    return {
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      if (method != null) 'method': method,
      if (notes != null) 'notes': notes,
    };
  }
}

class DebtRecord {
  final String? id;
  final dynamic customer; // Can be Customer object or just customerId String
  final List<DebtItem> items;
  final double totalAmount;
  final double amountPaid;
  final String status; // 'UNPAID', 'PARTIALLY_PAID', 'PAID'
  final List<PaymentEntry> paymentHistory;
  final DateTime debtDate;
  final DateTime? dueDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DebtRecord({
    this.id,
    required this.customer,
    required this.items,
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.paymentHistory,
    required this.status,
    required this.debtDate,
    this.dueDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  String get customerId {
    if (customer is Customer) {
      return (customer as Customer).id!;
    } else if (customer is String) {
      return customer as String;
    }
    // Handle if customer is a Map (from populated JSON but not yet full Customer object)
    else if (customer is Map<String, dynamic> && customer['_id'] != null) {
      return customer['_id'] as String;
    }
    throw Exception(
      "Customer ID could not be determined from customer data: $customer",
    );
  }

  String get customerName {
    if (customer is Customer) {
      return (customer as Customer).name;
    }
    // Handle if customer is a Map (from populated JSON but not yet full Customer object)
    else if (customer is Map<String, dynamic> && customer['name'] != null) {
      return customer['name'] as String;
    }
    return "N/A"; // Or fetch if only ID is present and name is needed
  }

  factory DebtRecord.fromJson(Map<String, dynamic> json) {
    dynamic customerData = json['customer'];
    Customer? parsedCustomer;
    if (customerData is Map<String, dynamic>) {
      parsedCustomer = Customer.fromJson(customerData);
    }

    return DebtRecord(
      id: json['_id'] as String?,
      customer: parsedCustomer ?? customerData,
      items:
          (json['items'] as List<dynamic>)
              .map(
                (itemJson) =>
                    DebtItem.fromJson(itemJson as Map<String, dynamic>),
              )
              .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      // Parse the paymentHistory list
      paymentHistory:
          (json['paymentHistory'] as List<dynamic>? ?? []) // Handle if null
              .map(
                (entryJson) =>
                    PaymentEntry.fromJson(entryJson as Map<String, dynamic>),
              )
              .toList(),
      status: json['status'] as String,
      debtDate: DateTime.parse(json['debtDate'] as String),
      dueDate:
          json['dueDate'] != null
              ? DateTime.tryParse(json['dueDate'] as String)
              : null,
      notes: json['notes'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null,
    );
  }

  // toJson remains largely the same for creating a new debt,
  // as paymentHistory is typically not sent on initial creation,
  // or would be an empty array.
  // For updates, the service layer will construct the specific payload.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'customer': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      // totalAmount is calculated by backend
      // amountPaid is calculated by backend from paymentHistory
      // initial status is set by backend
      'debtDate': debtDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      // Send initial amountPaid as a payment entry if it exists and it's a new debt.
      // This part of toJson might only be relevant for initial creation IF you allow an initial payment.
      // Otherwise, paymentHistory is managed via updates.
      // For simplicity, let's assume initial amountPaid is 0 and payments are added later.
      // If you want to support an initial payment during creation:
      // 'paymentHistory': amountPaid > 0 ? [PaymentEntry(amount: amountPaid, paymentDate: debtDate).toJson()] : [],
    };
  }
}

// Helper class for paginated debt response
class PaginatedDebtRecordsResponse {
  final List<DebtRecord> debtRecords;
  final int currentPage;
  final int totalPages;
  final int totalDebtRecords;
  final String?
  customerName; // Optional, if API returns it for customer-specific debt lists

  PaginatedDebtRecordsResponse({
    required this.debtRecords,
    required this.currentPage,
    required this.totalPages,
    required this.totalDebtRecords,
    this.customerName,
  });

  factory PaginatedDebtRecordsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedDebtRecordsResponse(
      debtRecords:
          (json['debtRecords'] as List<dynamic>)
              .map((e) => DebtRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalDebtRecords: json['totalDebtRecords'] as int,
      customerName: json['customerName'] as String?,
    );
  }
}
