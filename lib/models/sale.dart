/// One line of a cash sale as stored by the backend.
class SaleItem {
  final String productName;
  final String unitLabel;
  final double quantity;
  final double price;
  final double totalPrice;

  const SaleItem({
    required this.productName,
    required this.unitLabel,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
    productName: json['productName'] as String? ?? '',
    unitLabel: json['unitLabel'] as String? ?? '',
    quantity: (json['quantity'] as num).toDouble(),
    price: (json['price'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
  );
}

class Sale {
  final String id;
  final List<SaleItem> items;
  final double totalAmount;
  final double? amountReceived;
  final String paymentMethod;
  final DateTime saleDate;

  const Sale({
    required this.id,
    required this.items,
    required this.totalAmount,
    this.amountReceived,
    this.paymentMethod = 'Tunai',
    required this.saleDate,
  });

  double? get change =>
      amountReceived == null ? null : amountReceived! - totalAmount;

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['_id'] as String? ?? '',
    items:
        (json['items'] as List<dynamic>? ?? [])
            .map((i) => SaleItem.fromJson(i as Map<String, dynamic>))
            .toList(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    amountReceived: (json['amountReceived'] as num?)?.toDouble(),
    paymentMethod: json['paymentMethod'] as String? ?? 'Tunai',
    saleDate:
        DateTime.tryParse(json['saleDate'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );
}
