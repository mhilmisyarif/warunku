class Customer {
  final String? id; // Nullable for new customers before saving
  final String name;
  final String? phoneNumber;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.phoneNumber,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] as String?,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      // createdAt and updatedAt are usually handled by the backend
    };
  }

  // For easy debugging
  @override
  String toString() {
    return 'Customer{id: $id, name: $name, phoneNumber: $phoneNumber, address: $address}';
  }
}

// Helper class for paginated customer response (if your API returns it like that)
class PaginatedCustomersResponse {
  final List<Customer> customers;
  final int currentPage;
  final int totalPages;
  final int totalCustomers;

  PaginatedCustomersResponse({
    required this.customers,
    required this.currentPage,
    required this.totalPages,
    required this.totalCustomers,
  });

  factory PaginatedCustomersResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedCustomersResponse(
      customers:
          (json['customers'] as List<dynamic>)
              .map((e) => Customer.fromJson(e as Map<String, dynamic>))
              .toList(),
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalCustomers: json['totalCustomers'] as int,
    );
  }
}
