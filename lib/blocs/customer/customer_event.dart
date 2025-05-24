// lib/blocs/customer/customer_event.dart
part of 'customer_bloc.dart'; // Will be created next

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

// Event to load/fetch customers, with optional search and pagination
class LoadCustomers extends CustomerEvent {
  final String searchTerm;
  final int page;
  final int limit;
  final bool refresh;

  const LoadCustomers({
    this.searchTerm = '',
    this.page = 1,
    this.limit = 10,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [searchTerm, page, limit];
}

// Event to fetch a single customer by ID
class LoadCustomerById extends CustomerEvent {
  final String customerId;

  const LoadCustomerById(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// Event to add a new customer
class AddCustomer extends CustomerEvent {
  final Customer customer;

  const AddCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

// Event to update an existing customer
class UpdateCustomer extends CustomerEvent {
  final String customerId;
  final Customer customer;

  const UpdateCustomer(this.customerId, this.customer);

  @override
  List<Object?> get props => [customerId, customer];
}

// Event to delete a customer
class DeleteCustomer extends CustomerEvent {
  final String customerId;

  const DeleteCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}
