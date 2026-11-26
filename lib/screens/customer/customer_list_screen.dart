import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/customer/customer_bloc.dart';
import '../../models/customer.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/error_view.dart';
import '../../widgets/search_bar.dart';
import '../debt/debt_list_screen.dart';
import '../debt/debt_record_form_screen.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _scrollController = ScrollController();
  Timer? _debounce;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      context.read<CustomerBloc>().add(const LoadMoreCustomers());
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchTerm = query;
      _load();
    });
  }

  void _load() =>
      context.read<CustomerBloc>().add(LoadCustomers(searchTerm: _searchTerm));

  Future<void> _refresh() async {
    final bloc =
        context.read<CustomerBloc>()
          ..add(LoadCustomers(searchTerm: _searchTerm));
    await bloc.stream.firstWhere(
      (s) => s is CustomersLoaded || s is CustomerError,
    );
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
        bottom: ProductSearchBar(
          onChanged: _onSearchChanged,
          hintText: 'Cari nama atau nomor HP...',
        ),
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        buildWhen: (_, current) => current.isListState,
        builder: (context, state) {
          return switch (state) {
            CustomersLoaded() => _buildList(state),
            CustomerError(:final message) => ErrorView(
              message: message,
              onRetry: _load,
            ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_customer', // Tabs stay mounted; default tags would clash.
        onPressed: () => _open(const CustomerFormScreen()),
        tooltip: 'Tambah Pelanggan',
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Pelanggan'),
      ),
    );
  }

  Widget _buildList(CustomersLoaded state) {
    final customers = state.customers;
    return RefreshIndicator(
      onRefresh: _refresh,
      child:
          customers.isEmpty
              ? ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyView(
                    icon: Icons.people_outline,
                    message:
                        state.searchTerm.isEmpty
                            ? 'Belum ada pelanggan. Ketuk + untuk menambah.'
                            : 'Pelanggan "${state.searchTerm}" tidak ditemukan.',
                  ),
                ],
              )
              : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 96),
                itemCount: customers.length + (state.hasReachedMax ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index == customers.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _CustomerTile(
                    customer: customers[index],
                    onTap:
                        () => _open(
                          DebtListScreen(filterByCustomer: customers[index]),
                        ),
                    onAddDebt:
                        () => _open(
                          DebtRecordFormScreen(customer: customers[index]),
                        ),
                  );
                },
              ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.onTap,
    required this.onAddDebt,
  });

  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onAddDebt;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CustomerAvatar(customer),
        title: Text(
          customer.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(customer.phoneNumber ?? 'Tanpa nomor HP'),
        trailing: IconButton.filledTonal(
          icon: const Icon(Icons.post_add_rounded),
          tooltip: 'Catat Utang',
          onPressed: onAddDebt,
        ),
        onTap: onTap,
      ),
    );
  }
}
