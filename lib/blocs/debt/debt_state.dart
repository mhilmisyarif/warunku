part of 'debt_bloc.dart';

sealed class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object?> get props => [];
}

// --- Data states: drive what a debt screen shows. ---

class DebtInitial extends DebtState {}

class DebtLoading extends DebtState {}

class DebtsLoaded extends DebtState {
  final List<DebtRecord> debtRecords;
  final String? customerId;
  final DebtStatus? status;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const DebtsLoaded({
    required this.debtRecords,
    this.customerId,
    this.status,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  DebtsLoaded copyWith({
    List<DebtRecord>? debtRecords,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) => DebtsLoaded(
    debtRecords: debtRecords ?? this.debtRecords,
    customerId: customerId,
    status: status,
    currentPage: currentPage ?? this.currentPage,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    debtRecords,
    customerId,
    status,
    currentPage,
    hasReachedMax,
    isLoadingMore,
  ];
}

class DebtLoaded extends DebtState {
  final DebtRecord debtRecord;
  const DebtLoaded(this.debtRecord);

  @override
  List<Object?> get props => [debtRecord];
}

class DebtError extends DebtState {
  final String message;
  const DebtError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Operation states: one-off results of add/payment, for listeners. ---

class DebtSaving extends DebtState {}

class DebtOperationSuccess extends DebtState {
  final String message;
  const DebtOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class DebtOperationFailure extends DebtState {
  final String message;
  const DebtOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

extension DebtStateX on DebtState {
  /// Whether this state describes data to show (vs. an operation result).
  bool get isDataState =>
      this is DebtInitial ||
      this is DebtLoading ||
      this is DebtsLoaded ||
      this is DebtLoaded ||
      this is DebtError;
}
