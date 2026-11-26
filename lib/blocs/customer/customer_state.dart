part of 'customer_bloc.dart';

sealed class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

// --- List states: drive the customer list. ---

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomersLoaded extends CustomerState {
  final List<Customer> customers;
  final String searchTerm;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const CustomersLoaded({
    required this.customers,
    this.searchTerm = '',
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  CustomersLoaded copyWith({
    List<Customer>? customers,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) => CustomersLoaded(
    customers: customers ?? this.customers,
    searchTerm: searchTerm,
    currentPage: currentPage ?? this.currentPage,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    customers,
    searchTerm,
    currentPage,
    hasReachedMax,
    isLoadingMore,
  ];
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Operation states: one-off results of save/delete, for listeners. ---

class CustomerSaving extends CustomerState {}

class CustomerOperationSuccess extends CustomerState {
  final String message;
  const CustomerOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerOperationFailure extends CustomerState {
  final String message;
  const CustomerOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

extension CustomerStateX on CustomerState {
  /// Whether this state describes the customer list (vs. a save/delete result).
  bool get isListState =>
      this is CustomerInitial ||
      this is CustomerLoading ||
      this is CustomersLoaded ||
      this is CustomerError;
}
