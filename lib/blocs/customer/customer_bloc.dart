import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/customer.dart';
import '../../services/customer_service.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc(this._service) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoad);
    on<LoadMoreCustomers>(_onLoadMore);
    on<SaveCustomer>(_onSave);
    on<DeleteCustomer>(_onDelete);
  }

  final CustomerService _service;
  String _searchTerm = '';

  Future<void> _onLoad(LoadCustomers event, Emitter<CustomerState> emit) async {
    _searchTerm = event.searchTerm;
    emit(CustomerLoading());
    try {
      final page = await _service.getCustomers(searchTerm: event.searchTerm);
      // Drop results of a search that has since been superseded.
      if (event.searchTerm != _searchTerm) return;
      emit(
        CustomersLoaded(
          customers: page.customers,
          searchTerm: event.searchTerm,
          currentPage: page.currentPage,
          hasReachedMax: page.currentPage >= page.totalPages,
        ),
      );
    } catch (e) {
      if (event.searchTerm != _searchTerm) return;
      emit(CustomerError('Gagal memuat pelanggan: $e'));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    final current = state;
    if (current is! CustomersLoaded ||
        current.hasReachedMax ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _service.getCustomers(
        searchTerm: current.searchTerm,
        page: current.currentPage + 1,
      );
      final latest = state;
      // Ignore if the list was reloaded (e.g. new search) meanwhile.
      if (latest is! CustomersLoaded ||
          latest.searchTerm != current.searchTerm) {
        return;
      }
      final knownIds = latest.customers.map((c) => c.id).toSet();
      emit(
        latest.copyWith(
          customers: [
            ...latest.customers,
            ...page.customers.where((c) => !knownIds.contains(c.id)),
          ],
          currentPage: page.currentPage,
          hasReachedMax:
              page.customers.isEmpty || page.currentPage >= page.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      final latest = state;
      if (latest is CustomersLoaded) {
        emit(latest.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onSave(SaveCustomer event, Emitter<CustomerState> emit) async {
    final customer = event.customer;
    final isNew = customer.id == null;
    emit(CustomerSaving());
    try {
      if (isNew) {
        await _service.createCustomer(customer);
      } else {
        await _service.updateCustomer(customer.id!, customer);
      }
      emit(
        CustomerOperationSuccess(
          isNew ? 'Pelanggan ditambahkan.' : 'Pelanggan diperbarui.',
        ),
      );
      add(LoadCustomers(searchTerm: _searchTerm));
    } catch (e) {
      emit(CustomerOperationFailure('Gagal menyimpan pelanggan: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerSaving());
    try {
      await _service.deleteCustomer(event.customerId);
      emit(const CustomerOperationSuccess('Pelanggan dihapus.'));
      add(LoadCustomers(searchTerm: _searchTerm));
    } catch (e) {
      emit(CustomerOperationFailure('Gagal menghapus pelanggan: $e'));
    }
  }
}
