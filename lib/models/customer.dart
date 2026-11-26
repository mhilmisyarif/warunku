class Customer {
  /// Null for a customer that has not been saved yet.
  final String? id;
  final String name;
  final String? phoneNumber;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    this.id,
    required this.name,
    this.phoneNumber,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['_id'] as String?,
    name: json['name'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String?,
    address: json['address'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );

  /// Body for create/update requests; timestamps and id are owned by the backend.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (address != null) 'address': address,
  };

  @override
  String toString() => 'Customer{id: $id, name: $name}';
}

class PaginatedCustomersResponse {
  final List<Customer> customers;
  final int currentPage;
  final int totalPages;
  final int totalCustomers;

  const PaginatedCustomersResponse({
    required this.customers,
    required this.currentPage,
    required this.totalPages,
    required this.totalCustomers,
  });

  factory PaginatedCustomersResponse.fromJson(Map<String, dynamic> json) =>
      PaginatedCustomersResponse(
        customers:
            (json['customers'] as List<dynamic>? ?? [])
                .map((e) => Customer.fromJson(e as Map<String, dynamic>))
                .toList(),
        currentPage: json['currentPage'] as int? ?? 1,
        totalPages: json['totalPages'] as int? ?? 1,
        totalCustomers: json['totalCustomers'] as int? ?? 0,
      );
}
