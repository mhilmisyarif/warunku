import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/debt/debt_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../models/customer.dart';
import '../../models/debt_record.dart';
import '../../models/product.dart';
import '../../services/debt_service.dart';
import '../../utils/formatter.dart';
import '../../utils/theme.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_selection_dialog.dart';

/// Records a new debt for [customer]. Pops with `true` once saved.
class DebtRecordFormScreen extends StatelessWidget {
  const DebtRecordFormScreen({
    super.key,
    required this.customer,
    this.initialItems = const [],
  });

  final Customer customer;

  /// Pre-filled lines, e.g. from the cart. Empty = one blank line.
  final List<CartLine> initialItems;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DebtBloc(context.read<DebtService>()),
      child: _DebtRecordForm(customer: customer, initialItems: initialItems),
    );
  }
}

/// One line of the debt being entered.
class _ItemEntry {
  _ItemEntry({this.product, this.unit, double quantity = 1})
    : quantity = TextEditingController(text: formatQuantity(quantity));

  Product? product;
  ProductUnit? unit;
  final TextEditingController quantity;

  double get subtotal =>
      (double.tryParse(quantity.text) ?? 0) * (unit?.sellingPrice ?? 0);
}

class _DebtRecordForm extends StatefulWidget {
  const _DebtRecordForm({required this.customer, required this.initialItems});

  final Customer customer;
  final List<CartLine> initialItems;

  @override
  State<_DebtRecordForm> createState() => _DebtRecordFormState();
}

class _DebtRecordFormState extends State<_DebtRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _amountPaidController = TextEditingController();
  late final List<_ItemEntry> _items = [
    for (final line in widget.initialItems)
      _ItemEntry(
        product: line.product,
        unit: line.unit,
        quantity: line.quantity,
      ),
    if (widget.initialItems.isEmpty) _ItemEntry(),
  ];
  DateTime _debtDate = DateTime.now();
  DateTime? _dueDate;

  double get _grandTotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void dispose() {
    _notesController.dispose();
    _amountPaidController.dispose();
    for (final item in _items) {
      item.quantity.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (due ? _dueDate : _debtDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => due ? _dueDate = picked : _debtDate = picked);
    }
  }

  Future<void> _selectProduct(_ItemEntry item) async {
    final result = await showDialog<ProductSelectionResult>(
      context: context,
      builder: (_) => const ProductSelectionDialog(),
    );
    if (result != null) {
      setState(() {
        item.product = result.product;
        item.unit = result.selectedUnit;
      });
    }
  }

  void _removeItem(_ItemEntry item) {
    setState(() => _items.remove(item));
    item.quantity.dispose();
  }

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_items.any((item) => item.product == null)) {
      showResultSnackBar(
        messenger,
        'Pilih produk untuk setiap barang.',
        success: false,
      );
      return;
    }
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
    if (amountPaid > _grandTotal) {
      showResultSnackBar(
        messenger,
        'Pembayaran awal tidak boleh melebihi total.',
        success: false,
      );
      return;
    }

    final items = [
      for (final item in _items)
        DebtItem(
          productId: item.product!.id,
          productName: item.product!.name,
          unitLabel: item.unit!.label,
          quantity: double.parse(item.quantity.text),
          priceAtTimeOfDebt: item.unit!.sellingPrice,
          totalPrice: item.subtotal,
        ),
    ];
    context.read<DebtBloc>().add(
      AddDebtRecord(
        DebtRecord(
          customerId: widget.customer.id!,
          items: items,
          totalAmount: _grandTotal,
          amountPaid: amountPaid,
          debtDate: _debtDate,
          dueDate: _dueDate,
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Utang Baru')),
      bottomNavigationBar: BottomActionBar(
        summary: Row(
          children: [
            Text(
              'Total keseluruhan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              CurrencyFormatter.format(_grandTotal),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        child: BlocBuilder<DebtBloc, DebtState>(
          builder: (context, state) {
            final saving = state is DebtSaving;
            return FilledButton.icon(
              onPressed: saving ? null : _submit,
              icon:
                  saving
                      ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              label: const Text('Simpan Catatan Utang'),
            );
          },
        ),
      ),
      body: BlocListener<DebtBloc, DebtState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state is DebtOperationSuccess) {
            showResultSnackBar(messenger, state.message);
            // Saving a debt deducts stock on the server.
            context.read<ProductBloc>().add(const RefreshProducts());
            Navigator.of(context).pop(true);
          } else if (state is DebtOperationFailure) {
            showResultSnackBar(messenger, state.message, success: false);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CustomerAvatar(widget.customer),
                  title: Text(
                    widget.customer.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    widget.customer.phoneNumber ?? 'Tanpa nomor HP',
                  ),
                ),
              ),
              _DateField(
                label: 'Tanggal utang*',
                icon: Icons.calendar_today,
                date: _debtDate,
                onTap: () => _pickDate(due: false),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Barang', style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Tambah Barang'),
                    onPressed: () => setState(() => _items.add(_ItemEntry())),
                  ),
                ],
              ),
              for (final item in _items) _buildItem(item),
              const SizedBox(height: 12),
              _DateField(
                label: 'Jatuh tempo (opsional)',
                icon: Icons.event_busy,
                date: _dueDate,
                onTap: () => _pickDate(due: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountPaidController,
                decoration: const InputDecoration(
                  labelText: 'Dibayar sekarang (opsional)',
                  prefixIcon: Icon(Icons.payment),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final amount = double.tryParse(value);
                  return (amount == null || amount < 0)
                      ? 'Jumlah tidak valid'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(_ItemEntry item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectProduct(item),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Produk*',
                        suffixIcon: Icon(Icons.search),
                      ),
                      child: Text(
                        item.product == null
                            ? 'Ketuk untuk pilih produk'
                            : '${item.product!.name} (${item.unit!.label})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              item.product == null
                                  ? Theme.of(context).hintColor
                                  : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.danger,
                    ),
                    tooltip: 'Hapus Barang Ini',
                    onPressed: () => _removeItem(item),
                  ),
              ],
            ),
            if (item.unit != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: item.quantity,
                      decoration: const InputDecoration(labelText: 'Jumlah*'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final qty = double.tryParse(value ?? '');
                        return (qty == null || qty <= 0) ? 'Tidak valid' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '× ${CurrencyFormatter.format(item.unit!.sellingPrice)}\n'
                      '= ${CurrencyFormatter.format(item.subtotal)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.icon,
    required this.date,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Text(
          date == null ? 'Pilih tanggal' : DateFormatter.display(date!),
        ),
      ),
    );
  }
}
