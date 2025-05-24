part of 'debt_bloc.dart'; // Will be created next

abstract class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object?> get props => [];
}

// Initial state
class DebtInitial extends DebtState {}

// Loading state
class DebtLoading extends DebtState {
  final bool isFetchingMore; // To differentiate initial load from "load more"
  const DebtLoading({this.isFetchingMore = false});

  @override
  List<Object?> get props => [isFetchingMore];
}

// State when multiple debt records are successfully loaded
class DebtsLoaded extends DebtState {
  final List<DebtRecord> debtRecords;
  final int currentPage;
  final int totalPages;
  final int totalDebtRecords;
  final bool hasReachedMax;
  final String?
  customerName; // Optional, if fetching debts for a specific customer

  const DebtsLoaded({
    required this.debtRecords,
    required this.currentPage,
    required this.totalPages,
    required this.totalDebtRecords,
    this.hasReachedMax = false,
    this.customerName,
  });

  DebtsLoaded copyWith({
    List<DebtRecord>? debtRecords,
    int? currentPage,
    int? totalPages,
    int? totalDebtRecords,
    bool? hasReachedMax,
    String? customerName, // Allow updating customerName if needed
  }) {
    return DebtsLoaded(
      debtRecords: debtRecords ?? this.debtRecords,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalDebtRecords: totalDebtRecords ?? this.totalDebtRecords,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      customerName: customerName ?? this.customerName,
    );
  }

  @override
  List<Object?> get props => [
    debtRecords,
    currentPage,
    totalPages,
    totalDebtRecords,
    hasReachedMax,
    customerName,
  ];
}

// State when a single debt record is successfully loaded
class DebtLoaded extends DebtState {
  final DebtRecord debtRecord;

  const DebtLoaded(this.debtRecord);

  @override
  List<Object?> get props => [debtRecord];
}

// State for successful operations (add, update) that don't necessarily return a list
class DebtOperationSuccess extends DebtState {
  final String message;
  final DebtRecord? debtRecord; // Optionally return the affected debt record

  const DebtOperationSuccess({required this.message, this.debtRecord});

  @override
  List<Object?> get props => [message, debtRecord];
}

// Error state
class DebtError extends DebtState {
  final String message;

  const DebtError(this.message);

  @override
  List<Object?> get props => [message];
}
