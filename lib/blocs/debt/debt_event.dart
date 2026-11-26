part of 'debt_bloc.dart';

sealed class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the first page of debts, optionally for one customer and/or status.
class LoadDebts extends DebtEvent {
  final String? customerId;
  final DebtStatus? status;
  const LoadDebts({this.customerId, this.status});

  @override
  List<Object?> get props => [customerId, status];
}

/// Appends the next page for the current filters.
class LoadMoreDebts extends DebtEvent {
  const LoadMoreDebts();
}

class LoadDebtById extends DebtEvent {
  final String debtId;
  const LoadDebtById(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

class AddDebtRecord extends DebtEvent {
  final DebtRecord debtRecord;
  const AddDebtRecord(this.debtRecord);

  @override
  List<Object?> get props => [debtRecord];
}

class RecordPayment extends DebtEvent {
  final String debtId;
  final PaymentEntry payment;
  const RecordPayment(this.debtId, this.payment);

  @override
  List<Object?> get props => [debtId, payment];
}
