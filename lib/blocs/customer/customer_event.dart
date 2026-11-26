part of 'customer_bloc.dart';

sealed class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the first page of customers matching [searchTerm].
class LoadCustomers extends CustomerEvent {
  final String searchTerm;
  const LoadCustomers({this.searchTerm = ''});

  @override
  List<Object?> get props => [searchTerm];
}

/// Appends the next page for the current search.
class LoadMoreCustomers extends CustomerEvent {
  const LoadMoreCustomers();
}

/// Creates [customer], or updates it when it has an id.
class SaveCustomer extends CustomerEvent {
  final Customer customer;
  const SaveCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomer extends CustomerEvent {
  final String customerId;
  const DeleteCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}
