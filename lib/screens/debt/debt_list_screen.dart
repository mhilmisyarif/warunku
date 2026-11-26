import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/debt/debt_bloc.dart';
import '../../models/customer.dart';
import '../../models/debt_record.dart';
import '../../services/debt_service.dart';
import '../../utils/formatter.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/debt_status_badge.dart';
import '../../widgets/error_view.dart';
import '../customer/customer_form_screen.dart';
import 'debt_detail_screen.dart';
import 'debt_record_form_screen.dart';

/// Lists debts, for one customer when [filterByCustomer] is set.
class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key, this.filterByCustomer});

  final Customer? filterByCustomer;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              DebtBloc(context.read<DebtService>())
                ..add(LoadDebts(customerId: filterByCustomer?.id)),
      child: _DebtList(customer: filterByCustomer),
    );
  }
}

class _DebtList extends StatefulWidget {
  const _DebtList({this.customer});

  final Customer? customer;

  @override
  State<_DebtList> createState() => _DebtListState();
}

class _DebtListState extends State<_DebtList> {
  final _scrollController = ScrollController();
  DebtStatus? _status;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent * 0.9) {
        context.read<DebtBloc>().add(const LoadMoreDebts());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load() => context.read<DebtBloc>().add(
    LoadDebts(customerId: widget.customer?.id, status: _status),
  );

  void _setStatus(DebtStatus? status) {
    setState(() => _status = status);
    _load();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load(); // Debts may have changed (payment, new record).
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return Scaffold(
      appBar: AppBar(
        title: Text(customer?.name ?? 'Utang'),
        actions: [
          if (customer != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah Pelanggan',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerFormScreen(customer: customer),
                    ),
                  ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (customer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  CustomerAvatar(customer, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      [
                        customer.phoneNumber,
                        customer.address,
                      ].whereType<String>().join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _status == null,
                  onSelected: (_) => _setStatus(null),
                ),
                for (final status in DebtStatus.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => _setStatus(status),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DebtBloc, DebtState>(
              buildWhen: (_, current) => current.isDataState,
              builder: (context, state) {
                return switch (state) {
                  DebtsLoaded() => _buildList(state),
                  DebtError(:final message) => ErrorView(
                    message: message,
                    onRetry: _load,
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                };
              },
            ),
          ),
        ],
      ),
      // Adding needs a customer; the all-debts view has no customer picker.
      floatingActionButton:
          customer == null
              ? null
              : FloatingActionButton.extended(
                onPressed:
                    () => _open(DebtRecordFormScreen(customer: customer)),
                tooltip: 'Catat Utang Baru',
                icon: const Icon(Icons.post_add_rounded),
                label: const Text('Utang'),
              ),
    );
  }

  Widget _buildList(DebtsLoaded state) {
    final debts = state.debtRecords;
    if (debts.isEmpty) {
      return const EmptyView(
        icon: Icons.receipt_long_outlined,
        message: 'Tidak ada catatan utang untuk filter ini.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        _load();
        await context.read<DebtBloc>().stream.firstWhere(
          (s) => s is DebtsLoaded || s is DebtError,
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        itemCount: debts.length + (state.hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == debts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final debt = debts[index];
          return Hero(
            tag: 'debt_hero_${debt.id}',
            child: _DebtCard(
              debt: debt,
              showCustomer: widget.customer == null,
              onTap: () => _open(DebtDetailScreen(debtId: debt.id!)),
            ),
          );
        },
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.showCustomer,
    required this.onTap,
  });

  final DebtRecord debt;
  final bool showCustomer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = DebtStatusBadge.colorOf(debt.status);
    final itemCount = debt.items.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showCustomer ? debt.customerName : '$itemCount barang',
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormatter.display(debt.debtDate)} · '
                      'Total ${CurrencyFormatter.format(debt.totalAmount)}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(debt.remainingBalance),
                    style: textTheme.titleMedium?.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  DebtStatusBadge(debt.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
