import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date and currency formatting
import '../../blocs/debt/debt_bloc.dart';
import '../../models/debt_record.dart';
import '../../models/customer.dart'; // For Customer type hint

class DebtDetailScreen extends StatefulWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch event to load the specific debt record
    context.read<DebtBloc>().add(LoadDebtById(widget.debtId));
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'UNPAID':
        return Colors.redAccent;
      case 'PARTIALLY_PAID':
        return Colors.orangeAccent;
      case 'PAID':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showRecordPaymentDialog(BuildContext context, DebtRecord currentDebt) {
    final TextEditingController paymentController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    double remainingBalance = currentDebt.totalAmount - currentDebt.amountPaid;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Debt: ${_formatCurrency(currentDebt.totalAmount)}'),
                Text(
                  'Already Paid: ${_formatCurrency(currentDebt.amountPaid)}',
                ),
                Text(
                  'Remaining Balance: ${_formatCurrency(remainingBalance)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: paymentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'New Payment Amount',
                    hintText: 'Enter amount',
                    prefixText: 'Rp ',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Invalid number';
                    }
                    if (amount <= 0) {
                      return 'Payment must be positive';
                    }
                    if (amount > remainingBalance) {
                      return 'Payment exceeds remaining balance';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Record Payment'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final double paymentAmount = double.parse(
                    paymentController.text,
                  );
                  final double newTotalPaid =
                      currentDebt.amountPaid + paymentAmount;

                  Map<String, dynamic> updateData = {
                    'amountPaid': newTotalPaid,
                    // The backend pre-save hook should update the status based on the new amountPaid
                  };

                  // Dispatch update event
                  context.read<DebtBloc>().add(
                    UpdateDebtRecord(currentDebt.id!, updateData),
                  );
                  Navigator.of(dialogContext).pop(); // Close dialog
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debt Details')),
      body: BlocConsumer<DebtBloc, DebtState>(
        listener: (context, state) {
          if (state is DebtOperationSuccess &&
              state.debtRecord?.id == widget.debtId) {
            // If the updated/successful operation was for THIS debt, refresh its details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // The BlocBuilder will rebuild with the new state.debtRecord
          } else if (state is DebtError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        // buildWhen: (previous, current) {
        //   // Only rebuild if the relevant debt data has changed or loading states
        //   if (current is DebtLoaded && current.debtRecord.id == widget.debtId) return true;
        //   if (current is DebtLoading || current is DebtInitial || current is DebtError) return true;
        //   if (current is DebtOperationSuccess && current.debtRecord?.id == widget.debtId) return true; // Rebuild on success for this debt
        //   return false;
        // },
        builder: (context, state) {
          if (state is DebtLoading && (state is! DebtLoaded)) {
            // Show loading if not already showing loaded data
            final S =
                context
                    .read<DebtBloc>()
                    .state; // check if current data is available
            if (S is DebtLoaded && S.debtRecord.id == widget.debtId) {
              // Keep showing old data while new is loading from an update.
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }

          if (state is DebtLoaded && state.debtRecord.id == widget.debtId) {
            final debt = state.debtRecord;
            final remainingBalance = debt.totalAmount - debt.amountPaid;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DebtBloc>().add(LoadDebtById(widget.debtId));
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  _buildDetailCard(
                    title: 'Customer Information',
                    children: [
                      _buildDetailRow(
                        'Name:',
                        debt.customerName,
                      ), // Uses the customerName getter
                      if (debt.customer
                          is Customer) // Check if customer is populated
                        _buildDetailRow(
                          'Phone:',
                          (debt.customer as Customer).phoneNumber ?? 'N/A',
                        ),
                      if (debt.customer is Customer)
                        _buildDetailRow(
                          'Address:',
                          (debt.customer as Customer).address ?? 'N/A',
                        ),
                      if (debt.customer is String) // If only ID is stored
                        _buildDetailRow(
                          'Customer ID:',
                          debt.customer as String,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    title: 'Debt Summary',
                    children: [
                      _buildDetailRow(
                        'Debt Date:',
                        DateFormat.yMMMMd().format(debt.debtDate),
                      ),
                      if (debt.dueDate != null)
                        _buildDetailRow(
                          'Due Date:',
                          DateFormat.yMMMMd().format(debt.dueDate!),
                        ),
                      _buildDetailRow(
                        'Status:',
                        debt.status,
                        valueColor: _getStatusColor(debt.status),
                        valueStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildDetailRow(
                        'Total Amount:',
                        _formatCurrency(debt.totalAmount),
                      ),
                      _buildDetailRow(
                        'Amount Paid:',
                        _formatCurrency(debt.amountPaid),
                      ),
                      _buildDetailRow(
                        'Remaining Balance:',
                        _formatCurrency(remainingBalance),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              remainingBalance > 0
                                  ? Colors.redAccent
                                  : Colors.green,
                        ),
                      ),
                      if (debt.notes != null && debt.notes!.isNotEmpty)
                        _buildDetailRow('Notes:', debt.notes!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Items (${debt.items.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...debt.items
                      .map(
                        (item) => Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} x ${item.unitLabel} @ ${_formatCurrency(item.priceAtTimeOfDebt)}',
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    _formatCurrency(item.totalPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 24),
                  if (debt.status != 'PAID')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Record Payment'),
                      onPressed: () => _showRecordPaymentDialog(context, debt),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Placeholder for Edit Debt (could navigate back to DebtRecordFormScreen in edit mode)
                  // if (debt.status != 'PAID') // Usually cannot edit items if already paid
                  //   OutlinedButton.icon(
                  //     icon: const Icon(Icons.edit_note),
                  //     label: const Text('Edit Debt Items/Notes'),
                  //     onPressed: () { /* Navigate to DebtRecordFormScreen in edit mode */ },
                  //   ),
                ],
              ),
            );
          } else if (state is DebtError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading debt details: ${state.message}'),
                  ElevatedButton(
                    onPressed:
                        () => context.read<DebtBloc>().add(
                          LoadDebtById(widget.debtId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          // Fallback or if the state is for a different debt ID
          return const Center(child: Text('Loading debt details...'));
        },
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 16, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              style:
                  valueStyle ??
                  TextStyle(color: valueColor, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
