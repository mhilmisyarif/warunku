import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date and currency formatting
import 'package:warunku/utils/formatter.dart';
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
    final TextEditingController paymentAmountController =
        TextEditingController();
    final TextEditingController paymentMethodController =
        TextEditingController(); // Optional
    final TextEditingController paymentNotesController =
        TextEditingController();

    // Controller and variable for the Payment Date
    final TextEditingController paymentDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()), // Default to today
    );
    DateTime selectedPaymentDate =
        DateTime.now(); // Holds the actual DateTime object

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    double remainingBalance = currentDebt.totalAmount - currentDebt.amountPaid;
    bool _isProcessingPayment = false; // Local state for dialog's loading

    showDialog(
      context: context,
      barrierDismissible:
          !_isProcessingPayment, // Prevent dismissing while processing
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage _isProcessingPayment within the dialog
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: const Text('Record Payment'),
              content: Form(
                key: formKey,
                child: Container(
                  width: double.maxFinite,

                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ... (Text widgets for debt info remain the same) ...
                        Text(
                          'Total Debt: ${CurrencyFormatter.format(currentDebt.totalAmount)}',
                        ),
                        Text(
                          'Already Paid: ${CurrencyFormatter.format(currentDebt.amountPaid)}',
                        ),
                        Text(
                          'Remaining Balance: ${CurrencyFormatter.format(remainingBalance)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: paymentAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Payment Amount*',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled:
                              !_isProcessingPayment, // Disable while processing
                          // ... (validator and decoration remain the same) ...
                          validator: (value) {
                            // Ensure validator uses remainingBalance from dialog scope
                            if (value == null || value.isEmpty)
                              return 'Please enter an amount';
                            final amount = double.tryParse(value);
                            if (amount == null) return 'Invalid number';
                            if (amount <= 0) return 'Payment must be positive';
                            if (amount > remainingBalance)
                              return 'Payment exceeds remaining balance';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          // Payment Date Picker
                          controller: paymentDateController,
                          decoration: const InputDecoration(
                            labelText: 'Payment Date*',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true, // Make it read-only
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: dialogContext, // Use dialogContext here
                              initialDate: selectedPaymentDate,
                              firstDate: DateTime(
                                2000,
                              ), // Or a more reasonable start date
                              lastDate:
                                  DateTime.now(), // Prevent future dates for payments
                            );
                            if (pickedDate != null &&
                                pickedDate != selectedPaymentDate) {
                              stfSetState(() {
                                // Use StatefulBuilder's setState to update the dialog UI
                                selectedPaymentDate = pickedDate;
                                paymentDateController.text = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(selectedPaymentDate);
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a payment date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        TextFormField(
                          controller: paymentMethodController,
                          decoration: const InputDecoration(
                            labelText: 'Payment Method (Optional)',
                            hintText: 'e.g., Cash, Transfer',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: paymentNotesController,
                          decoration: const InputDecoration(
                            labelText: 'Payment Notes (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    // Disable while processing
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Record Payment'),
                  onPressed: () {
                    // Disable while processing
                    if (formKey.currentState!.validate()) {
                      final newPaymentEntry = PaymentEntry(
                        amount: double.parse(paymentAmountController.text),
                        paymentDate:
                            selectedPaymentDate, // Use the selectedPaymentDate
                        method:
                            paymentMethodController.text.trim().isNotEmpty
                                ? paymentMethodController.text.trim()
                                : null,
                        notes:
                            paymentNotesController.text.trim().isNotEmpty
                                ? paymentNotesController.text.trim()
                                : null,
                      );

                      // Construct the updateData for the service
                      // This structure depends on how your backend controller expects 'newPayment'
                      Map<String, dynamic> updatePayload = {
                        'newPayment': newPaymentEntry.toJson(),
                        // You can also send other fields to update on the DebtRecord itself, like general notes if needed
                        // 'notes': 'General debt notes if changed',
                      };

                      // Access BLoC using the screen's context, not dialogContext
                      BlocProvider.of<DebtBloc>(
                        context,
                      ).add(UpdateDebtRecord(currentDebt.id!, updatePayload));

                      // The BlocListener on DebtDetailScreen will handle SnackBar and closing dialog
                      // Or, you can pop here IF AND ONLY IF BLoC operations are quick and success is assumed.
                      // It's better to let the BlocListener handle popping after success.
                      // For now, we pop immediately and rely on BlocListener in main screen.
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debt Details')),
      body: BlocConsumer<DebtBloc, DebtState>(
        listenWhen: (previous, current) {
          // Only listen if the current state is relevant for a side-effect (SnackBar)
          // and if it's for the current debt.
          if (current is DebtLoaded &&
              current.debtRecord.id == widget.debtId &&
              previous is DebtLoading) {
            // This condition means data just loaded, possibly after an update that went through a loading phase.
            // Or, if update doesn't have its own loading state, this is after initial load.
            // We need a better way to know if it was due to an update.
            // For now, let's assume ANY DebtLoaded for this ID after an action is "success".
            // This might show the snackbar on initial load too, which might be okay or not.
            return true;
          }
          if (current is DebtError) return true;
          return false; // Default don't listen
        },
        listener: (context, state) {
          print("DebtDetailScreen LISTENER: state=$state"); // DEBUG
          if (state is DebtLoaded && state.debtRecord.id == widget.debtId) {
            // To differentiate initial load vs. update success:
            // This is tricky without a dedicated "OperationSuccess" state.
            // Let's assume for now we show it if data is loaded.
            // A better way: the payment dialog could set a flag that this listener checks.
            // For simplicity now:
            // ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove any previous
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text("Debt details updated!"), backgroundColor: Colors.blue),
            // );
            // The above would show on every load. We only want it after payment.
            // We'll rely on the dialog closing as the primary feedback for payment submission success for now,
            // and the UI just updating. If you need a specific "Payment Successful" SnackBar,
            // keeping DebtOperationSuccess or a similar dedicated event/state is cleaner.

            // Let's revert to keeping DebtOperationSuccess for clearer SnackBar logic
            // and focus on why the builder isn't picking up DebtLoaded correctly after it.
            // The BLoC emitting DebtLoaded then DebtOperationSuccess (from turn 64) was a good pattern.
            // The problem is likely still in buildWhen or builder logic.
            ScaffoldMessenger.of(
              context,
            ).removeCurrentSnackBar(); // Remove previous
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Payment recorded. Debt details updated!"),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is DebtError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        buildWhen: (previous, current) {
          print(
            "DebtDetailScreen buildWhen: previous=$previous, current=$current",
          );
          if (current is DebtOperationSuccess) {
            // This was from my previous suggestion for DebtBloc emissions
            print(
              "DebtDetailScreen buildWhen: Is DebtOperationSuccess, returning FALSE",
            );
            return false;
          }
          if (current is DebtLoaded) {
            bool isRelevant = current.debtRecord.id == widget.debtId;
            bool hasDataChanged = true;
            if (previous is DebtLoaded &&
                previous.debtRecord.id == current.debtRecord.id) {
              hasDataChanged = previous.debtRecord != current.debtRecord;
            }
            bool should = isRelevant && hasDataChanged;
            print(
              "DebtDetailScreen buildWhen: Is DebtLoaded (singular), relevant=$isRelevant, dataChanged=$hasDataChanged, returning $should",
            );
            return should;
          }
          bool should =
              current is DebtInitial ||
              current is DebtLoading ||
              current is DebtError;
          print(
            "DebtDetailScreen buildWhen: Is $current (other type), returning $should",
          );
          return should;
        },
        builder: (context, state) {
          print(
            "DebtDetailScreen BUILDER: state=$state, for debtId=${widget.debtId}",
          );

          if (state is DebtLoaded && state.debtRecord.id == widget.debtId) {
            final debt = state.debtRecord;
            final remainingBalance = debt.totalAmount - debt.amountPaid;
            print(
              "DebtDetailScreen BUILDER: Displaying DebtLoaded for ${debt.id}",
            );
            return Hero(
              tag: 'debt_hero_${widget.debtId}',
              child: Material(
                type: MaterialType.transparency,
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<DebtBloc>().add(LoadDebtById(widget.debtId));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: <Widget>[
                      _buildDetailCard(
                        title: 'Customer Information',
                        children: [
                          _buildDetailRow('Name:', debt.customerName),
                          if (debt.customer is Customer)
                            _buildDetailRow(
                              'Phone:',
                              (debt.customer as Customer).phoneNumber ?? 'N/A',
                            ),
                          if (debt.customer is Customer)
                            _buildDetailRow(
                              'Address:',
                              (debt.customer as Customer).address ?? 'N/A',
                            ),
                          if (debt.customer is String)
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
                            CurrencyFormatter.format(debt.totalAmount),
                          ),
                          _buildDetailRow(
                            'Amount Paid:',
                            CurrencyFormatter.format(debt.amountPaid),
                          ),
                          _buildDetailRow(
                            'Remaining Balance:',
                            CurrencyFormatter.format(remainingBalance),
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
                                      '${item.quantity} x ${item.unitLabel} @ ${CurrencyFormatter.format(item.priceAtTimeOfDebt)}',
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        CurrencyFormatter.format(
                                          item.totalPrice,
                                        ),
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
                      if (debt.paymentHistory.isNotEmpty) ...[
                        Text(
                          'Payment History',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: debt.paymentHistory.length,
                          itemBuilder: (context, index) {
                            final payment = debt.paymentHistory[index];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(
                                  'Paid: ${CurrencyFormatter.format(payment.amount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${DateFormat.yMMMd().add_jm().format(payment.paymentDate)}',
                                    ),
                                    if (payment.method != null &&
                                        payment.method!.isNotEmpty)
                                      Text('Method: ${payment.method}'),
                                    if (payment.notes != null &&
                                        payment.notes!.isNotEmpty)
                                      Text('Notes: ${payment.notes}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (debt.status != 'PAID')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text('Record Payment'),
                          onPressed:
                              () => _showRecordPaymentDialog(context, debt),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          } else if (state is DebtError) {
            print("DebtDetailScreen BUILDER: Displaying DebtError"); // DEBUG
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
          } else {
            // This covers DebtInitial, DebtLoading, or any other state
            // that passed buildWhen but isn't DebtLoaded for the correct ID or DebtError.
            // It should primarily show for the initial loading of this screen.
            return const Center(child: CircularProgressIndicator());
          }
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
