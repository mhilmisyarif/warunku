import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/debt_record.dart';
import '../../services/debt_service.dart';

part 'debt_event.dart';
part 'debt_state.dart';

/// Not global: each debt screen creates its own instance, so a list, a detail
/// view and a form never overwrite each other's state.
class DebtBloc extends Bloc<DebtEvent, DebtState> {
  DebtBloc(this._service) : super(DebtInitial()) {
    on<LoadDebts>(_onLoad);
    on<LoadMoreDebts>(_onLoadMore);
    on<LoadDebtById>(_onLoadById);
    on<AddDebtRecord>(_onAdd);
    on<RecordPayment>(_onRecordPayment);
  }

  final DebtService _service;
  LoadDebts? _latestLoad;

  Future<void> _onLoad(LoadDebts event, Emitter<DebtState> emit) async {
    _latestLoad = event;
    emit(DebtLoading());
    try {
      final page = await _service.getDebtRecords(
        customerId: event.customerId,
        status: event.status,
      );
      // Drop results of a filter change that has since been superseded.
      if (!identical(event, _latestLoad)) return;
      emit(
        DebtsLoaded(
          debtRecords: page.debtRecords,
          customerId: event.customerId,
          status: event.status,
          currentPage: page.currentPage,
          hasReachedMax: page.currentPage >= page.totalPages,
        ),
      );
    } catch (e) {
      if (!identical(event, _latestLoad)) return;
      emit(DebtError('Gagal memuat utang: $e'));
    }
  }

  Future<void> _onLoadMore(LoadMoreDebts event, Emitter<DebtState> emit) async {
    final current = state;
    if (current is! DebtsLoaded ||
        current.hasReachedMax ||
        current.isLoadingMore) {
      return;
    }
    final load = _latestLoad;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _service.getDebtRecords(
        customerId: current.customerId,
        status: current.status,
        page: current.currentPage + 1,
      );
      final latest = state;
      if (latest is! DebtsLoaded || !identical(load, _latestLoad)) return;
      final knownIds = latest.debtRecords.map((d) => d.id).toSet();
      emit(
        latest.copyWith(
          debtRecords: [
            ...latest.debtRecords,
            ...page.debtRecords.where((d) => !knownIds.contains(d.id)),
          ],
          currentPage: page.currentPage,
          hasReachedMax:
              page.debtRecords.isEmpty || page.currentPage >= page.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      final latest = state;
      if (latest is DebtsLoaded) emit(latest.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onLoadById(LoadDebtById event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      emit(DebtLoaded(await _service.getDebtRecordById(event.debtId)));
    } catch (e) {
      emit(DebtError('Gagal memuat utang: $e'));
    }
  }

  Future<void> _onAdd(AddDebtRecord event, Emitter<DebtState> emit) async {
    emit(DebtSaving());
    try {
      await _service.createDebtRecord(event.debtRecord);
      emit(const DebtOperationSuccess('Catatan utang ditambahkan.'));
    } catch (e) {
      emit(DebtOperationFailure('Gagal menambah utang: $e'));
    }
  }

  Future<void> _onRecordPayment(
    RecordPayment event,
    Emitter<DebtState> emit,
  ) async {
    emit(DebtSaving());
    try {
      final updated = await _service.addPayment(event.debtId, event.payment);
      emit(const DebtOperationSuccess('Pembayaran dicatat.'));
      emit(DebtLoaded(updated));
    } catch (e) {
      emit(DebtOperationFailure('Gagal mencatat pembayaran: $e'));
    }
  }
}
