// lib/screens/customer/customer_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../models/customer.dart';
import '../../widgets/search_bar.dart'; //

// Placeholder for navigation - we'll create these screens later
import 'customer_form_screen.dart';
// import 'customer_detail_screen.dart'; // Or directly to a new debt screen

import '../debt/debt_record_form_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Local list to manage displayed customers, including pagination accumulation
  List<Customer> _displayedCustomers = [];
  // To track current search term that led to the _displayedCustomers
  String _currentSearchTerm = '';
  // To track current page for the _displayedCustomers
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    // Initial load is handled by the BLoC provider in main.dart

    _scrollController.addListener(_onScroll);
    // No need to add listener to _searchController here,
    // onChanged in ProductSearchBar will trigger _onSearchChanged directly.
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose(); // Dispose the controller itself
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final currentState = context.read<CustomerBloc>().state;
    if (currentState is CustomersLoaded && !currentState.hasReachedMax) {
      if (_isBottom &&
          !(context.read<CustomerBloc>().state is CustomerLoading)) {
        // Check BLoC state for loading
        context.read<CustomerBloc>().add(
          LoadCustomers(
            searchTerm: _searchController.text,
            page: currentState.currentPage + 1,
          ),
        );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<CustomerBloc>().add(
        LoadCustomers(
          searchTerm: query,
          page: 1,
          refresh: true,
        ), // refresh flag
      );
    });
  }

  void _navigateToCustomerForm({Customer? customer}) async {
    // Placeholder for actual navigation
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: customer),
      ),
    );
    if (result == true && mounted) {
      // Assuming form returns true on success
      // Trigger a refresh
      context.read<CustomerBloc>().add(
        LoadCustomers(
          searchTerm: _searchController.text,
          page: 1,
          refresh: true,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigate to Customer Form. Editing: ${customer?.name ?? 'New Customer'}',
        ),
      ),
    );
  }

  void _navigateToCustomerDetails(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebtRecordFormScreen(customer: customer),
      ),
    ).then((success) {
      if (success == true && mounted) {
        // Optionally refresh customer specific debt list if this screen was showing that
        // Or the DebtListScreen will refresh if it's visible and its listener picks up success
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ProductSearchBar(
          // Reusing ProductSearchBar
          onChanged:
              _onSearchChanged, // Directly call the debounced search handler
          // You might want to pass the _searchController to the ProductSearchBar
          // if it needs to manage its own text, or ensure ProductSearchBar calls onChanged correctly.
          // For now, let's assume ProductSearchBar's onChanged gives the query string.
        ),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Trigger a refresh after successful CUD operations
            context.read<CustomerBloc>().add(
              LoadCustomers(
                searchTerm: _searchController.text,
                page: 1,
                refresh: true,
              ),
            );
          } else if (state is CustomerError && _displayedCustomers.isEmpty) {
            // Only show full screen error if there's nothing else to show
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Handle data accumulation for pagination
          if (state is CustomersLoaded) {
            if (state.currentPage == 1 ||
                _searchController.text != _currentSearchTerm) {
              // New search or first page
              _displayedCustomers = List.from(state.customers);
              _currentSearchTerm =
                  _searchController.text; // Update current search term
              _currentPage = 1;
            } else if (state.currentPage > _currentPage) {
              // Appending new page data
              // Avoid duplicates if BLoC somehow re-emits same page
              final existingIds = _displayedCustomers.map((c) => c.id).toSet();
              _displayedCustomers.addAll(
                state.customers.where((c) => !existingIds.contains(c.id)),
              );
              _currentPage = state.currentPage;
            }
            // if isLoadingMore is handled by BLoC state: state is CustomerLoading && state.isFetchingMore

            if (_displayedCustomers.isEmpty) {
              return Center(
                child: Text(
                  _searchController.text.isEmpty
                      ? 'No customers found. Add one!'
                      : 'No customers found for "${_searchController.text}".',
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<CustomerBloc>().add(
                  LoadCustomers(
                    searchTerm: _searchController.text,
                    page: 1,
                    refresh: true,
                  ),
                );
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount:
                    _displayedCustomers.length + (state.hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index >= _displayedCustomers.length) {
                    // It's the +1 item, show loader if not hasReachedMax
                    return state.hasReachedMax
                        ? const SizedBox.shrink() // Nothing more to load
                        : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                  }
                  final customer = _displayedCustomers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(customer.phoneNumber ?? 'No phone number'),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.edit_note,
                          color: Theme.of(context).primaryColor,
                        ),
                        tooltip: 'Edit Customer',
                        onPressed:
                            () => _navigateToCustomerForm(customer: customer),
                      ),
                      onTap: () => _navigateToCustomerDetails(customer),
                    ),
                  );
                },
              ),
            );
          } else if (state is CustomerLoading && _displayedCustomers.isEmpty) {
            // Only show full screen loader if there are no customers currently displayed
            return const Center(child: CircularProgressIndicator());
          } else if (state is CustomerError && _displayedCustomers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load customers: ${state.message}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CustomerBloc>().add(
                          LoadCustomers(
                            searchTerm: _searchController.text,
                            page: 1,
                            refresh: true,
                          ),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Fallback or initial state before any data/loading for displayed customers
          if (_displayedCustomers.isNotEmpty) {
            // If there's an error but we have old data, show the old data
            // (the listener would have shown a snackbar for the error)
            return ListView.builder(
              /* ... similar to above but without loading indicator ... */
              controller: _scrollController,
              itemCount: _displayedCustomers.length,
              itemBuilder: (context, index) {
                final customer = _displayedCustomers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(customer.name),
                    subtitle: Text(customer.phoneNumber ?? 'No phone number'),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.edit_note,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Edit Customer',
                      onPressed:
                          () => _navigateToCustomerForm(customer: customer),
                    ),
                    onTap: () => _navigateToCustomerDetails(customer),
                  ),
                );
              },
            );
          }
          return const Center(
            child: Text('Pull to refresh or add a new customer.'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCustomerForm(),
        tooltip: 'Add Customer',
        child: const Icon(Icons.add),
      ),
    );
  }
}
