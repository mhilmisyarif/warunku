import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/debt/debt_bloc.dart';
import '../../models/debt_record.dart';
import '../../services/debt_service.dart';
import '../../utils/formatter.dart';
import '../../utils/theme.dart';
import '../../widgets/customer_avatar.dart';
import '../../widgets/debt_status_badge.dart';
import '../../widgets/error_view.dart';

class DebtDetailScreen extends StatelessWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              DebtBloc(context.read<DebtService>())..add(LoadDebtById(debtId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail Utang')),
        body: BlocConsumer<DebtBloc, DebtState>(
          listenWhen: (_, current) => !current.isDataState,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            if (state is DebtOperationSuccess) {
              showResultSnackBar(messenger, state.message);
            } else if (state is DebtOperationFailure) {
              showResultSnackBar(messenger, state.message, success: false);
            }
          },
          buildWhen: (_, current) => current.isDataState,
          builder: (context, state) {
            return switch (state) {
              DebtLoaded(:final debtRecord) => Hero(
                tag: 'debt_hero_$debtId',
                child: Material(
                  type: MaterialType.transparency,
                  child: _DebtDetails(debt: debtRecord),
                ),
              ),
              DebtError(:final message) => ErrorView(
                message: message,
                onRetry:
                    () => context.read<DebtBloc>().add(LoadDebtById(debtId)),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
      ),
    );
  }
}

class _DebtDetails extends StatelessWidget {
  const _DebtDetails({required this.debt});

  final DebtRecord debt;

  Future<void> _recordPayment(BuildContext context) async {
    final bloc = context.read<DebtBloc>();
    final payment = await showDialog<PaymentEntry>(
      context: context,
      builder: (_) => _RecordPaymentDialog(remaining: debt.remainingBalance),
    );
    if (payment != null) bloc.add(RecordPayment(debt.id!, payment));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final customer = debt.customer;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final bloc =
                  context.read<DebtBloc>()..add(LoadDebtById(debt.id!));
              await bloc.stream.firstWhere(
                (s) => s is DebtLoaded || s is DebtError,
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _SummaryCard(debt: debt),
                const SizedBox(height: 16),
                _Section(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          customer != null
                              ? CustomerAvatar(customer)
                              : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        debt.customerName,
                        style: textTheme.titleMedium,
                      ),
                      subtitle:
                          customer?.phoneNumber != null
                              ? Text(customer!.phoneNumber!)
                              : null,
                    ),
                    if (customer?.address != null)
                      _Row('Alamat', customer!.address!),
                    _Row('Tanggal utang', DateFormatter.display(debt.debtDate)),
                    if (debt.dueDate != null)
                      _Row('Jatuh tempo', DateFormatter.display(debt.dueDate!)),
                    if (debt.notes?.isNotEmpty ?? false)
                      _Row('Catatan', debt.notes!),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Barang (${debt.items.length})',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _Section(
                  children: [
                    for (final (i, item) in debt.items.indexed) ...[
                      if (i > 0) const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${formatQuantity(item.quantity)} ${item.unitLabel} × '
                                    '${CurrencyFormatter.format(item.priceAtTimeOfDebt)}',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.totalPrice),
                              style: textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (debt.paymentHistory.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Riwayat Pembayaran', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _Section(
                    children: [
                      for (final (i, payment)
                          in debt.paymentHistory.indexed) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.success.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.south_west_rounded,
                              color: AppTheme.success,
                            ),
                          ),
                          title: Text(
                            CurrencyFormatter.format(payment.amount),
                            style: textTheme.titleMedium?.copyWith(
                              color: AppTheme.success,
                            ),
                          ),
                          subtitle: Text(
                            [
                              DateFormatter.display(payment.paymentDate),
                              if (payment.method?.isNotEmpty ?? false)
                                payment.method!,
                              if (payment.notes?.isNotEmpty ?? false)
                                payment.notes!,
                            ].join(' · '),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (debt.status != DebtStatus.paid)
          BottomActionBar(
            child: FilledButton.icon(
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Catat Pembayaran'),
              onPressed: () => _recordPayment(context),
            ),
          ),
      ],
    );
  }
}

/// Remaining balance up front, with paid-vs-total progress.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.debt});

  final DebtRecord debt;

  @override
  Widget build(BuildContext context) {
    const white70 = TextStyle(color: Colors.white70, fontSize: 13);
    const whiteBold = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    final progress =
        debt.totalAmount > 0
            ? (debt.amountPaid / debt.totalAmount).clamp(0.0, 1.0)
            : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF14A085)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Sisa utang', style: white70)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DebtStatusBadge(debt.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(debt.remainingBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dibayar', style: white70),
                    Text(
                      CurrencyFormatter.format(debt.amountPaid),
                      style: whiteBold,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total', style: white70),
                  Text(
                    CurrencyFormatter.format(debt.totalAmount),
                    style: whiteBold,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collects a payment; pops with a [PaymentEntry] or null when cancelled.
class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({required this.remaining});

  final double remaining;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _method = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _method.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    Navigator.pop(
      context,
      PaymentEntry(
        amount: double.parse(_amount.text),
        paymentDate: _date,
        method: optional(_method),
        notes: optional(_notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catat Pembayaran'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sisa utang: ${CurrencyFormatter.format(widget.remaining)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Jumlah*',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Masukkan jumlah lebih dari 0';
                  }
                  if (amount > widget.remaining) {
                    return 'Melebihi sisa utang';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal bayar*',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormatter.display(_date)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _method,
                decoration: const InputDecoration(
                  labelText: 'Metode (opsional)',
                  hintText: 'mis. Tunai, Transfer',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
