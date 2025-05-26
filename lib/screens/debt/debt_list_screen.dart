// lib/screens/debt/debt_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:warunku/screens/debt/debt_record_form_screen.dart';
import '../customer/customer_list_screen.dart'; // For navigating to select a customer
import '../../blocs/debt/debt_bloc.dart';
import '../../models/debt_record.dart';
import '../../models/customer.dart'; // To potentially display customer name if ID only
// import '../../widgets/search_bar.dart'; // We might need a more complex filter UI here
// Placeholder for navigation
import 'debt_record_form_screen.dart';
// import 'debt_detail_screen.dart';

class DebtListScreen extends StatefulWidget {
  final Customer?
  filterByCustomer; // Optional: To show debts for a specific customer

  const DebtListScreen({super.key, this.filterByCustomer});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<DebtRecord> _displayedDebts = [];
  String _currentStatusFilter = ''; // e.g., "UNPAID", "PAID", "" for all
  String? _currentCustomerIdFilter;
  int _currentPage = 1; // Keep track of the current page for displayed data

  // TODO: Implement date range filter UI and state
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  @override
  void initState() {
    super.initState();
    _currentCustomerIdFilter = widget.filterByCustomer?.id;
    _loadDebts(refresh: true); // Initial load

    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant DebtListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the filterByCustomer changes, reload the debts
    if (widget.filterByCustomer?.id != oldWidget.filterByCustomer?.id) {
      _currentCustomerIdFilter = widget.filterByCustomer?.id;
      _loadDebts(refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDebts({bool refresh = false, String? status}) {
    if (refresh) {
      _currentPage = 1; // Reset page for a fresh load
      _displayedDebts = []; // Clear displayed debts on refresh
    }
    if (status != null) {
      _currentStatusFilter = status;
    }

    context.read<DebtBloc>().add(
      LoadDebts(
        customerId: _currentCustomerIdFilter,
        status: _currentStatusFilter,
        // startDate: _startDateFilter?.toIso8601String(),
        // endDate: _endDateFilter?.toIso8601String(),
        page: _currentPage,
        refresh: refresh,
      ),
    );
  }

  void _onScroll() {
    final currentState = context.read<DebtBloc>().state;
    if (currentState is DebtsLoaded && !currentState.hasReachedMax) {
      if (_isBottom &&
          !(context.read<DebtBloc>().state is DebtLoading &&
              (context.read<DebtBloc>().state as DebtLoading).isFetchingMore)) {
        context.read<DebtBloc>().add(
          LoadDebts(
            customerId: _currentCustomerIdFilter,
            status: _currentStatusFilter,
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

  void _navigateToDebtForm({DebtRecord? debtRecord}) async {
    // Make it async
    Customer? customerForDebt;

    if (widget.filterByCustomer != null) {
      customerForDebt = widget.filterByCustomer;
    } else {
      // If no specific customer is pre-selected (e.g., viewing all debts),
      // we need to let the user choose a customer.
      final selectedCustomer = await Navigator.push<Customer?>(
        // Expect a Customer or null
        context,
        MaterialPageRoute(
          // You might want a dedicated customer selection screen/dialog
          // For now, let's reuse CustomerListScreen for selection (needs modification to return selection)
          // OR, for simplicity here, show a dialog to pick from existing customers
          // This is a simplified example for customer selection:
          builder:
              (context) =>
                  const CustomerListScreen(), // This screen needs to be adapted to return a selected customer
          // Or show a simpler selection dialog
        ),
      );

      if (selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customer selected. Debt creation cancelled.'),
          ),
        );
        return; // User cancelled or didn't select a customer
      }
      customerForDebt = selectedCustomer;
    }

    // At this point, customerForDebt should be non-null if we proceed
    if (customerForDebt != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DebtRecordFormScreen(
                customer:
                    customerForDebt!, // Now we are sure it's not null here
                debtRecordToEdit: debtRecord,
              ),
        ),
      );
      if (result == true && mounted) {
        _loadDebts(refresh: true);
      }
    }
  }

  void _navigateToDebtDetails(DebtRecord debt) {
    // Placeholder for actual navigation
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => DebtDetailScreen(debtId: debt.id!), // Pass ID
    //   ),
    // ).then((_) => _loadDebts(refresh: true)); // Refresh after returning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'View details for debt ID: ${debt.id} (to be implemented)',
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Wrap(
        spacing: 8.0,
        children: <Widget>[
          FilterChip(
            label: const Text('All'),
            selected: _currentStatusFilter == '',
            onSelected: (bool selected) {
              if (selected) _loadDebts(refresh: true, status: '');
            },
          ),
          FilterChip(
            label: const Text('Unpaid'),
            selected: _currentStatusFilter == 'UNPAID',
            onSelected: (bool selected) {
              if (selected) _loadDebts(refresh: true, status: 'UNPAID');
            },
            selectedColor: Colors.red[100],
          ),
          FilterChip(
            label: const Text('Partially Paid'),
            selected: _currentStatusFilter == 'PARTIALLY_PAID',
            onSelected: (bool selected) {
              if (selected) _loadDebts(refresh: true, status: 'PARTIALLY_PAID');
            },
            selectedColor: Colors.orange[100],
          ),
          FilterChip(
            label: const Text('Paid'),
            selected: _currentStatusFilter == 'PAID',
            onSelected: (bool selected) {
              if (selected) _loadDebts(refresh: true, status: 'PAID');
            },
            selectedColor: Colors.green[100],
          ),
          // TODO: Add Date Range Filter Button here
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    // You can use your existing CurrencyFormatter here if it's accessible
    // For simplicity, using intl package directly:
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'UNPAID':
        return Colors.red;
      case 'PARTIALLY_PAID':
        return Colors.orange;
      case 'PAID':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.filterByCustomer != null
              ? "${widget.filterByCustomer!.name}'s Debts"
              : 'All Debt Records',
        ),
        // TODO: Add a more advanced filter button if needed (for dates, specific customer if not pre-filtered)
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: BlocConsumer<DebtBloc, DebtState>(
              listener: (context, state) {
                if (state is DebtOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadDebts(refresh: true); // Refresh list
                } else if (state is DebtError && _displayedDebts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: ${state.message}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                // Logic to manage displayed debts based on BLoC state
                if (state is DebtsLoaded) {
                  if (state.currentPage ==
                          1 || // This was a refresh or first load for current filters
                      widget.filterByCustomer?.id !=
                          _currentCustomerIdFilter || // Customer filter changed
                      _currentStatusFilter !=
                          (context.read<DebtBloc>().state as DebtsLoaded?)
                              ?.debtRecords
                              .firstOrNull
                              ?.status // A bit crude, better to store filter in BLoC event/state
                              ) {
                    _displayedDebts = List.from(state.debtRecords);
                    _currentPage = 1;
                  } else if (state.currentPage > _currentPage) {
                    final existingIds =
                        _displayedDebts.map((d) => d.id).toSet();
                    _displayedDebts.addAll(
                      state.debtRecords.where(
                        (d) => !existingIds.contains(d.id),
                      ),
                    );
                    _currentPage = state.currentPage;
                  }
                  if (state.debtRecords.length < _displayedDebts.length &&
                      state.currentPage == 1) {
                    _displayedDebts = List.from(state.debtRecords);
                  }
                }

                if (state is DebtLoading &&
                    state.isFetchingMore == false &&
                    _displayedDebts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_displayedDebts.isEmpty && state is! DebtLoading) {
                  // Also handles DebtsLoaded with empty list
                  return Center(
                    child: Text(
                      'No debt records found for the current filters.',
                    ),
                  );
                }

                if (state is DebtError && _displayedDebts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Failed to load debts: ${state.message}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _loadDebts(refresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadDebts(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        _displayedDebts.length +
                        ((state is DebtsLoaded && !state.hasReachedMax) ||
                                (state is DebtLoading && state.isFetchingMore)
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index >= _displayedDebts.length) {
                        return (state is DebtsLoaded && state.hasReachedMax)
                            ? const SizedBox.shrink()
                            : const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                      }
                      final debt = _displayedDebts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        child: ListTile(
                          title: Text(
                            'Debt ID: ${debt.id?.substring(0, 8) ?? 'N/A'}...',
                          ), // Show partial ID
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer: ${debt.customerName} (${debt.customerId.substring(0, 6)}...)',
                              ), // Requires customerName to be populated or fetched
                              Text(
                                'Date: ${DateFormat.yMMMd().format(debt.debtDate)}',
                              ),
                              Text(
                                'Total: ${_formatCurrency(debt.totalAmount)}',
                              ),
                              Text('Paid: ${_formatCurrency(debt.amountPaid)}'),
                              Text(
                                'Status: ${debt.status}',
                                style: TextStyle(
                                  color: _getStatusColor(debt.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true, // Adjust if content overflows
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _navigateToDebtDetails(debt),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToDebtForm(),
        tooltip: 'Add New Debt',
        child: const Icon(Icons.post_add_rounded),
      ),
    );
  }
}
