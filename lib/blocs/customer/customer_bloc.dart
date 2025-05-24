// lib/blocs/customer/customer_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerService customerService;

  CustomerBloc({required this.customerService}) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<LoadCustomerById>(_onLoadCustomerById);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    final currentState = state;
    // If it's not the first page load and we are already loading, or have reached max, do nothing
    if (event.page > 1 &&
        (currentState is CustomerLoading ||
            (currentState is CustomersLoaded && currentState.hasReachedMax))) {
      return;
    }

    // For page 1, always show loading. For subsequent pages, only show if not already CustomersLoaded.
    if (event.page == 1 || currentState is! CustomersLoaded) {
      emit(CustomerLoading());
    }

    try {
      final paginatedResponse = await customerService.getCustomers(
        searchTerm: event.searchTerm,
        page: event.page,
        limit: event.limit,
      );

      if (currentState is CustomersLoaded && event.page > 1) {
        // Append new customers for infinite scrolling/load more
        emit(
          paginatedResponse.customers.isEmpty
              ? currentState.copyWith(hasReachedMax: true)
              : currentState.copyWith(
                customers: currentState.customers + paginatedResponse.customers,
                currentPage: paginatedResponse.currentPage,
                totalPages: paginatedResponse.totalPages,
                hasReachedMax:
                    paginatedResponse.customers.isEmpty ||
                    paginatedResponse.currentPage >=
                        paginatedResponse.totalPages,
              ),
        );
      } else {
        // First load or refresh
        emit(
          CustomersLoaded(
            customers: paginatedResponse.customers,
            currentPage: paginatedResponse.currentPage,
            totalPages: paginatedResponse.totalPages,
            totalCustomers: paginatedResponse.totalCustomers,
            hasReachedMax:
                paginatedResponse.customers.isEmpty ||
                paginatedResponse.currentPage >= paginatedResponse.totalPages,
          ),
        );
      }
    } catch (e) {
      emit(CustomerError("Failed to load customers: ${e.toString()}"));
    }
  }

  Future<void> _onLoadCustomerById(
    LoadCustomerById event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customer = await customerService.getCustomerById(event.customerId);
      emit(CustomerLoaded(customer));
    } catch (e) {
      emit(CustomerError("Failed to load customer details: ${e.toString()}"));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading()); // Or a specific CustomerAdding state
    try {
      final newCustomer = await customerService.createCustomer(event.customer);
      emit(
        CustomerOperationSuccess(
          message: "Customer added successfully!",
          customer: newCustomer,
        ),
      );
      // Optionally, you can dispatch LoadCustomers again to refresh the list,
      // or the UI can react to CustomerOperationSuccess to update itself.
      // add(const LoadCustomers()); // Example: refresh list
    } catch (e) {
      emit(CustomerError("Failed to add customer: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading()); // Or a specific CustomerUpdating state
    try {
      final updatedCustomer = await customerService.updateCustomer(
        event.customerId,
        event.customer,
      );
      emit(
        CustomerOperationSuccess(
          message: "Customer updated successfully!",
          customer: updatedCustomer,
        ),
      );
      // add(const LoadCustomers()); // Example: refresh list
    } catch (e) {
      emit(CustomerError("Failed to update customer: ${e.toString()}"));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading()); // Or a specific CustomerDeleting state
    try {
      await customerService.deleteCustomer(event.customerId);
      emit(
        const CustomerOperationSuccess(
          message: "Customer deleted successfully!",
        ),
      );
      // add(const LoadCustomers()); // Example: refresh list
    } catch (e) {
      emit(CustomerError("Failed to delete customer: ${e.toString()}"));
    }
  }
}
