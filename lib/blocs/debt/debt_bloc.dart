import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/debt_record.dart';
import '../../services/debt_service.dart';
import '../../services/customer_service.dart'; // If fetching debts by customer from CustomerService

part 'debt_event.dart';
part 'debt_state.dart';

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final DebtService debtService;
  final CustomerService customerService; // For fetching debts by customer ID

  DebtBloc({required this.debtService, required this.customerService})
    : super(DebtInitial()) {
    on<LoadDebts>(_onLoadDebts);
    on<LoadDebtById>(_onLoadDebtById);
    on<AddDebtRecord>(_onAddDebtRecord);
    on<UpdateDebtRecord>(_onUpdateDebtRecord);
  }

  Future<void> _onLoadDebts(LoadDebts event, Emitter<DebtState> emit) async {
    final currentState = state;

    // Prevent multiple rapid loads if not refreshing
    if (!event.refresh &&
        currentState is DebtLoading &&
        currentState.isFetchingMore)
      return;
    if (!event.refresh &&
        currentState is DebtsLoaded &&
        currentState.hasReachedMax &&
        event.page > currentState.currentPage)
      return;

    if (event.refresh || event.page == 1 || currentState is! DebtsLoaded) {
      emit(const DebtLoading(isFetchingMore: false)); // Initial load or refresh
    } else if (currentState is DebtsLoaded && !currentState.hasReachedMax) {
      emit(const DebtLoading(isFetchingMore: true)); // Loading more
    }

    try {
      PaginatedDebtRecordsResponse paginatedResponse;
      if (event.customerId != null && event.customerId!.isNotEmpty) {
        // Fetching debts for a specific customer
        paginatedResponse = await customerService.getDebtsByCustomerId(
          event.customerId!,
          status: event.status,
          startDate: event.startDate,
          endDate: event.endDate,
          page: event.page,
          limit: event.limit,
        );
      } else {
        // Fetching all debts (or filtered globally)
        paginatedResponse = await debtService.getDebtRecords(
          status: event.status,
          startDate: event.startDate,
          endDate: event.endDate,
          page: event.page,
          limit: event.limit,
        );
      }

      bool hasReachedMax =
          paginatedResponse.debtRecords.isEmpty ||
          paginatedResponse.currentPage >= paginatedResponse.totalPages;

      if (currentState is DebtsLoaded && !event.refresh && event.page > 1) {
        // Append new debt records for "load more"
        emit(
          currentState.copyWith(
            debtRecords:
                currentState.debtRecords + paginatedResponse.debtRecords,
            currentPage: paginatedResponse.currentPage,
            totalPages: paginatedResponse.totalPages,
            hasReachedMax: hasReachedMax,
            // customerName will be set if it's from customerService, otherwise null
            customerName:
                event.customerId != null
                    ? paginatedResponse.customerName
                    : null,
          ),
        );
      } else {
        // First load or refresh
        emit(
          DebtsLoaded(
            debtRecords: paginatedResponse.debtRecords,
            currentPage: paginatedResponse.currentPage,
            totalPages: paginatedResponse.totalPages,
            totalDebtRecords: paginatedResponse.totalDebtRecords,
            hasReachedMax: hasReachedMax,
            customerName:
                event.customerId != null
                    ? paginatedResponse.customerName
                    : null,
          ),
        );
      }
    } catch (e) {
      emit(DebtError("Failed to load debt records: ${e.toString()}"));
    }
  }

  Future<void> _onLoadDebtById(
    LoadDebtById event,
    Emitter<DebtState> emit,
  ) async {
    emit(const DebtLoading());
    try {
      final debtRecord = await debtService.getDebtRecordById(event.debtId);
      emit(DebtLoaded(debtRecord));
    } catch (e) {
      emit(DebtError("Failed to load debt details: ${e.toString()}"));
    }
  }

  Future<void> _onAddDebtRecord(
    AddDebtRecord event,
    Emitter<DebtState> emit,
  ) async {
    emit(const DebtLoading());
    try {
      final newDebtRecord = await debtService.createDebtRecord(
        event.debtRecord,
      );
      emit(
        DebtOperationSuccess(
          message: "Debt record added successfully!",
          debtRecord: newDebtRecord,
        ),
      );
      // Optionally dispatch LoadDebts to refresh the list shown in UI
      // e.g., add(LoadDebts(customerId: newDebtRecord.customerId, refresh: true));
    } catch (e) {
      emit(DebtError("Failed to add debt record: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateDebtRecord(
    UpdateDebtRecord event,
    Emitter<DebtState> emit,
  ) async {
    // Optional: emit a specific "DebtUpdating" state if you want fine-grained loading for the button
    // emit(DebtUpdating(debtId: event.debtId)); // You'd need to define this state

    try {
      final updatedDebtRecord = await debtService.updateDebtRecord(
        event.debtId,
        event.updateData,
      );

      if (updatedDebtRecord != null && updatedDebtRecord.id != null) {
        // Directly emit DebtLoaded with the updated record.
        // The UI will listen for this to update content AND to show a success message.
        emit(DebtLoaded(updatedDebtRecord));
      } else {
        emit(
          DebtError("Failed to retrieve updated debt details after payment."),
        );
      }
    } catch (e) {
      emit(DebtError("Failed to update debt record: ${e.toString()}"));
    }
  }
}
