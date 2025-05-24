part of 'debt_bloc.dart'; // Will be created next

abstract class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => [];
}

// Event to load debt records with filters and pagination
class LoadDebts extends DebtEvent {
  final String? customerId;
  final String
  status; // e.g., "UNPAID", "PARTIALLY_PAID", "PAID", or "" for all
  final String? startDate; // ISO8601 string
  final String? endDate; // ISO8601 string
  final int page;
  final int limit;
  final bool refresh; // To indicate if it's a fresh load or loading more

  const LoadDebts({
    this.customerId,
    this.status = '',
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 10,
    this.refresh = false, // Default to not a refresh (for load more)
  });

  @override
  List<Object?> get props => [
    customerId,
    status,
    startDate,
    endDate,
    page,
    limit,
    refresh,
  ];
}

// Event to load a single debt record by its ID
class LoadDebtById extends DebtEvent {
  final String debtId;

  const LoadDebtById(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

// Event to add a new debt record
class AddDebtRecord extends DebtEvent {
  final DebtRecord debtRecord; // This would contain customerId and items

  const AddDebtRecord(this.debtRecord);

  @override
  List<Object?> get props => [debtRecord];
}

// Event to update an existing debt record (e.g., for payments or status change)
class UpdateDebtRecord extends DebtEvent {
  final String debtId;
  final Map<String, dynamic>
  updateData; // e.g., {'amountPaid': 5000, 'status': 'PARTIALLY_PAID'}

  const UpdateDebtRecord(this.debtId, this.updateData);

  @override
  List<Object?> get props => [debtId, updateData];
}

// If you implement deleting debts (use with caution)
// class DeleteDebtRecord extends DebtEvent {
//   final String debtId;
//   const DeleteDebtRecord(this.debtId);
//   @override
//   List<Object?> get props => [debtId];
// }
