import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/product/product_bloc.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../services/sale_service.dart';
import '../../utils/formatter.dart';
import '../../utils/theme.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_card.dart';
import '../debt/debt_record_form_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _busy = false;

  /// Cart is done: empty it, refresh stock, leave.
  void _finish(String message) {
    context.read<CartCubit>().clear();
    context.read<ProductBloc>().add(const RefreshProducts());
    showResultSnackBar(ScaffoldMessenger.of(context), message);
    Navigator.pop(context);
  }

  Future<void> _payCash() async {
    final cart = context.read<CartCubit>();
    final received = await showDialog<double?>(
      context: context,
      builder: (_) => _CashDialog(total: cart.total),
    );
    if (received == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final sale = await context.read<SaleService>().createSale(
        cart.state,
        amountReceived: received,
      );
      if (!mounted) return;
      final change = sale.change ?? 0;
      _finish(
        change > 0
            ? 'Penjualan dicatat. Kembalian ${CurrencyFormatter.format(change)}.'
            : 'Penjualan dicatat.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showResultSnackBar(
        ScaffoldMessenger.of(context),
        'Gagal mencatat penjualan: $e',
        success: false,
      );
    }
  }

  Future<void> _recordAsDebt() async {
    final cart = context.read<CartCubit>();
    final customer = await showDialog<Customer>(
      context: context,
      builder: (_) => const _CustomerPickerDialog(),
    );
    if (customer == null || !mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => DebtRecordFormScreen(
              customer: customer,
              initialItems: cart.state,
            ),
      ),
    );
    if (saved == true && mounted) _finish('Utang ${customer.name} dicatat.');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, List<CartLine>>(
      builder: (context, lines) {
        final cart = context.read<CartCubit>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Keranjang'),
            actions: [
              if (lines.isNotEmpty)
                TextButton(
                  onPressed: _busy ? null : cart.clear,
                  child: const Text('Kosongkan'),
                ),
            ],
          ),
          body:
              lines.isEmpty
                  ? const EmptyView(
                    icon: Icons.shopping_cart_outlined,
                    message:
                        'Keranjang kosong. Tambahkan produk dari tab Produk.',
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: lines.length,
                    itemBuilder:
                        (context, i) => _CartLineTile(
                          line: lines[i],
                          onChanged:
                              _busy ? null : (q) => cart.setQuantity(i, q),
                        ),
                  ),
          bottomNavigationBar:
              lines.isEmpty
                  ? null
                  : BottomActionBar(
                    summary: Row(
                      children: [
                        Text(
                          'Total (${lines.length} barang)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          CurrencyFormatter.format(cart.total),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _recordAsDebt,
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Jadikan Utang'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _payCash,
                            icon:
                                _busy
                                    ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.payments_outlined),
                            label: const Text('Bayar Tunai'),
                          ),
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line, required this.onChanged});

  final CartLine line;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = ProductCard.categoryStyle(line.product.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${CurrencyFormatter.format(line.unit.sellingPrice)} / ${line.unit.label}',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(line.subtotal),
                    style: textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                line.quantity <= 1 ? Icons.delete_outline : Icons.remove,
                color: line.quantity <= 1 ? AppTheme.danger : null,
              ),
              tooltip: line.quantity <= 1 ? 'Hapus' : 'Kurangi',
              onPressed:
                  onChanged == null
                      ? null
                      : () => onChanged!(line.quantity - 1),
            ),
            Text(formatQuantity(line.quantity), style: textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Tambah',
              onPressed:
                  onChanged == null || !line.canIncrement
                      ? null
                      : () => onChanged!(line.quantity + 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks how much cash was handed over; pops with that amount (or the exact
/// total), or null when cancelled.
class _CashDialog extends StatefulWidget {
  const _CashDialog({required this.total});

  final double total;

  @override
  State<_CashDialog> createState() => _CashDialogState();
}

class _CashDialogState extends State<_CashDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Empty field means exact change.
  double? get _received {
    final text = _controller.text.trim();
    return text.isEmpty ? widget.total : double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    final received = _received;
    final change = received == null ? null : received - widget.total;
    final error =
        received == null
            ? 'Jumlah tidak valid'
            : change! < 0
            ? 'Uang kurang ${CurrencyFormatter.format(-change)}'
            : null;

    return AlertDialog(
      title: const Text('Bayar Tunai'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total: ${CurrencyFormatter.format(widget.total)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Uang diterima',
              prefixText: 'Rp ',
              hintText: 'Kosongkan jika uang pas',
              errorText: _controller.text.isEmpty ? null : error,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            'Kembalian: ${CurrencyFormatter.format(change != null && change > 0 ? change : 0)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed:
              error == null ? () => Navigator.pop(context, received) : null,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

/// Searchable customer list; pops with the chosen [Customer].
class _CustomerPickerDialog extends StatefulWidget {
  const _CustomerPickerDialog();

  @override
  State<_CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<_CustomerPickerDialog> {
  late Future<List<Customer>> _customers = _search('');
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<Customer>> _search(String term) async =>
      (await context.read<CustomerService>().getCustomers(
        searchTerm: term,
      )).customers;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Utang atas nama'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari pelanggan',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 300),
                  () => setState(() => _customers = _search(q)),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Customer>>(
                future: _customers,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final customers = snapshot.data!;
                  if (customers.isEmpty) {
                    return const Center(
                      child: Text('Pelanggan tidak ditemukan.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder:
                        (context, i) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CustomerAvatar(customers[i]),
                          title: Text(customers[i].name),
                          subtitle: Text(customers[i].phoneNumber ?? ''),
                          onTap: () => Navigator.pop(context, customers[i]),
                        ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
