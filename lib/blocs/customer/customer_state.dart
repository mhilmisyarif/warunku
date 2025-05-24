part of 'customer_bloc.dart'; // Will be created next

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

// Initial state
class CustomerInitial extends CustomerState {}

// Loading state
class CustomerLoading extends CustomerState {}

// State when multiple customers are successfully loaded
class CustomersLoaded extends CustomerState {
  final List<Customer> customers;
  final int currentPage;
  final int totalPages;
  final int totalCustomers;
  final bool hasReachedMax; // For pagination, true if no more pages

  const CustomersLoaded({
    required this.customers,
    required this.currentPage,
    required this.totalPages,
    required this.totalCustomers,
    this.hasReachedMax = false,
  });

  CustomersLoaded copyWith({
    List<Customer>? customers,
    int? currentPage,
    int? totalPages,
    int? totalCustomers,
    bool? hasReachedMax,
  }) {
    return CustomersLoaded(
      customers: customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [
    customers,
    currentPage,
    totalPages,
    totalCustomers,
    hasReachedMax,
  ];
}

// State when a single customer is successfully loaded
class CustomerLoaded extends CustomerState {
  final Customer customer;

  const CustomerLoaded(this.customer);

  @override
  List<Object?> get props => [customer];
}

// State for successful operations (add, update, delete) that don't necessarily return a list
class CustomerOperationSuccess extends CustomerState {
  final String message;
  final Customer? customer; // Optionally return the affected customer

  const CustomerOperationSuccess({required this.message, this.customer});

  @override
  List<Object?> get props => [message, customer];
}

// Error state
class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}
