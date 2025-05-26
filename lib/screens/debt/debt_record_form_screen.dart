// lib/screens/debt/debt_record_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../blocs/debt/debt_bloc.dart';
import '../../models/customer.dart';
import '../../models/debt_record.dart';
import '../../models/product.dart'; // To potentially select products
import '../../services/product_service.dart'; // To fetch product details/prices
import '../../widgets/product_selection_dialog.dart';
import '../../blocs/products/product_bloc.dart';

// A temporary class to manage form state for each debt item before saving
class _DebtItemEntry {
  String? productId; // Will be populated by product selection
  TextEditingController productNameController =
      TextEditingController(); // For display/manual entry initially
  TextEditingController unitLabelController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceAtTimeController = TextEditingController();
  Product? selectedProduct; // Store the full product if selected
  ProductUnit? selectedUnit; // Store the selected unit of the product

  _DebtItemEntry({
    this.productId,
    String? productName,
    String? unitLabel,
    String? quantity,
    String? priceAtTime,
    this.selectedProduct,
    this.selectedUnit,
  }) {
    productNameController.text = productName ?? '';
    unitLabelController.text = unitLabel ?? '';
    quantityController.text = quantity ?? '1'; // Default quantity to 1
    priceAtTimeController.text = priceAtTime ?? '';
  }

  void dispose() {
    productNameController.dispose();
    unitLabelController.dispose();
    quantityController.dispose();
    priceAtTimeController.dispose();
  }

  double get itemSubtotal {
    final qty = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceAtTimeController.text) ?? 0;
    return qty * price;
  }
}

class DebtRecordFormScreen extends StatefulWidget {
  final Customer customer; // Customer for whom the debt is being recorded
  final DebtRecord?
  debtRecordToEdit; // Optional: if editing an existing debt record

  const DebtRecordFormScreen({
    super.key,
    required this.customer,
    this.debtRecordToEdit,
  });

  @override
  State<DebtRecordFormScreen> createState() => _DebtRecordFormScreenState();
}

class _DebtRecordFormScreenState extends State<DebtRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _debtDateController;
  TextEditingController _dueDateController = TextEditingController();
  TextEditingController _notesController = TextEditingController();
  TextEditingController _amountPaidController = TextEditingController();

  List<_DebtItemEntry> _itemEntries = [];
  double _grandTotal = 0.0;

  bool get _isEditing => widget.debtRecordToEdit != null;

  // You'll need ProductService to fetch product prices if not manually entered
  // Could be provided via BlocProvider or GetIt if you use a service locator
  late ProductService _productService;

  @override
  void initState() {
    super.initState();
    _productService = ProductService(); // Simple instantiation for now

    _debtDateController = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(widget.debtRecordToEdit?.debtDate ?? DateTime.now()),
    );
    if (widget.debtRecordToEdit?.dueDate != null) {
      _dueDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(widget.debtRecordToEdit!.dueDate!);
    }
    _notesController.text = widget.debtRecordToEdit?.notes ?? '';
    _amountPaidController.text =
        widget.debtRecordToEdit?.amountPaid.toString() ?? '0';

    if (_isEditing && widget.debtRecordToEdit!.items.isNotEmpty) {
      _itemEntries =
          widget.debtRecordToEdit!.items.map((item) {
            // In a real edit scenario, you might want to fetch the product again
            // to ensure selectedProduct and selectedUnit are populated for UI consistency.
            // For now, we directly use the stored values.
            return _DebtItemEntry(
              productId: item.productId,
              productName: item.productName,
              unitLabel: item.unitLabel,
              quantity: item.quantity.toString(),
              priceAtTime: item.priceAtTimeOfDebt.toString(),
            );
          }).toList();
    } else {
      // Start with one empty item entry if not editing
      _addItemEntry();
    }
    _calculateGrandTotal();
  }

  @override
  void dispose() {
    _debtDateController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    _amountPaidController.dispose();
    for (var entry in _itemEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addItemEntry() {
    setState(() {
      _itemEntries.add(_DebtItemEntry());
    });
  }

  void _removeItemEntry(int index) {
    _itemEntries[index].dispose(); // Dispose controllers of the removed item
    setState(() {
      _itemEntries.removeAt(index);
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    double total = 0;
    for (var entry in _itemEntries) {
      total +=
          entry
              .itemSubtotal; // itemSubtotal getter in _DebtItemEntry uses its controllers
    }
    if (mounted) {
      // Check if widget is still in the tree before calling setState
      setState(() {
        _grandTotal = total;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          controller.text.isNotEmpty
              ? (DateFormat('yyyy-MM-dd').tryParse(controller.text) ??
                  DateTime.now())
              : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Placeholder for product selection logic
  Future<void> _selectProductForItem(int itemIndex) async {
    // This is where you would navigate to a product selection screen/modal
    // For now, let's simulate selecting a product and its unit
    // In a real app, this would involve:
    // 1. Opening a product search/list screen.
    // 2. User selects a product.
    // 3. User selects a unit for that product.
    // 4. The selected product, unit, and its current price are returned.

    // Example: Show a dialog to manually enter product ID for now, or choose from a few samples
    // For simplicity, we'll just allow manual entry in the existing fields for this first pass.
    // Or, directly fetch a sample product to demonstrate unit selection.

    // Let's assume we fetch a product (e.g., the first product from the service)
    // This is a very simplified example.
    try {
      // This is just an example, you'd have a proper product selection UI
      final ProductSelectionResult?
      result = await showDialog<ProductSelectionResult>(
        context: context,
        builder: (BuildContext dialogContext) {
          // If ProductSelectionDialog relies on context.read<ProductBloc>(),
          // make sure ProductBloc is provided above this point in the widget tree.
          // It's usually provided in main.dart via MultiBlocProvider.
          return const ProductSelectionDialog();
        },
      );

      if (result != null && mounted) {
        // Check mounted after async gap
        setState(() {
          final entry = _itemEntries[itemIndex];
          entry.selectedProduct = result.product;
          entry.selectedUnit = result.selectedUnit;
          entry.productId = result.product.id; // Ensure product ID is non-null
          entry.productNameController.text = result.product.name;
          entry.unitLabelController.text = result.selectedUnit.label;
          entry.priceAtTimeController.text =
              result.selectedUnit.sellingPrice.toString();
          // Quantity controller should remain as is, or default to 1 if product changes significantly
          // entry.quantityController.text = '1'; // Optional: Reset quantity on new product selection
          _calculateGrandTotal();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_itemEntries.any(
      (entry) => entry.selectedProduct == null || entry.productId == null,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product for all items.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_itemEntries.isEmpty && !_isEditing) {
      // Don't allow submitting empty new debt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the debt.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final List<DebtItem> finalItems = [];
    for (var entry in _itemEntries) {
      // Re-validate item specific fields that might not be covered by TextFormField validators
      // or ensure their controllers have valid numbers if using tryParse
      final double quantity =
          double.tryParse(entry.quantityController.text) ?? 0;
      final double priceAtTime =
          double.tryParse(entry.priceAtTimeController.text) ?? 0;

      // ProductId should be non-null due to the check above
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantity must be positive for item: ${entry.productNameController.text}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (entry.unitLabelController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unit label is missing for item: ${entry.productNameController.text}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      finalItems.add(
        DebtItem(
          productId: entry.productId!,
          productName:
              entry
                  .selectedProduct!
                  .name, // Use name from selectedProduct for accuracy
          unitLabel: entry.selectedUnit!.label, // Use label from selectedUnit
          quantity: quantity,
          priceAtTimeOfDebt: priceAtTime,
          totalPrice:
              quantity *
              priceAtTime, // Recalculate here for final submission accuracy
        ),
      );
    }

    // If editing and items list became empty, it means delete all items. Backend should handle this.
    if (_isEditing && finalItems.isEmpty) {
      print(
        "Warning: Submitting an edit with no items. Backend should handle this as deleting all items or disallow.",
      );
    }

    final debtDate =
        DateFormat('yyyy-MM-dd').tryParse(_debtDateController.text) ??
        DateTime.now();
    final dueDate =
        _dueDateController.text.isNotEmpty
            ? DateFormat('yyyy-MM-dd').tryParse(_dueDateController.text)
            : null;
    final initialAmountPaid =
        double.tryParse(_amountPaidController.text) ?? 0.0;

    // Recalculate grand total one last time from finalItems for submission
    final double finalGrandTotal = finalItems.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    if (initialAmountPaid > finalGrandTotal && finalGrandTotal > 0) {
      // allow paying 0 for 0 total
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount paid initially cannot exceed the grand total.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<PaymentEntry> initialPaymentHistory = [];
    if (initialAmountPaid > 0) {
      initialPaymentHistory.add(
        PaymentEntry(
          amount: initialAmountPaid,
          paymentDate:
              debtDate, // Or DateTime.now() if payment is considered "now"
          method:
              "Initial Payment", // Or leave null/empty, or add a field for this
        ),
      );
    }

    final debtRecordPayload = DebtRecord(
      id: widget.debtRecordToEdit?.id, // For updates
      customer: widget.customer.id!,
      items: finalItems,
      totalAmount: finalGrandTotal, // Send the calculated final total
      amountPaid: initialAmountPaid,
      paymentHistory:
          _isEditing
              ? (widget.debtRecordToEdit?.paymentHistory ??
                  []) // Preserve existing history if editing
              : initialPaymentHistory, // Use initial payment history for new records
      status:
          _isEditing
              ? widget
                  .debtRecordToEdit!
                  .status // Preserve existing status for edit (backend will re-evaluate)
              : (initialAmountPaid >= finalGrandTotal && finalGrandTotal > 0
                  ? 'PAID'
                  : (initialAmountPaid > 0 ? 'PARTIALLY_PAID' : 'UNPAID')),
      debtDate: debtDate,
      dueDate: dueDate,
      notes: _notesController.text.trim(),
    );

    if (_isEditing) {
      if (widget.debtRecordToEdit?.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Debt ID missing for update.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      // Ensure updateData for BLoC is correct.
      // The DebtBloc's UpdateDebtRecord event takes (String debtId, Map<String, dynamic> updateData)
      // So we need to convert the debtRecordPayload to a suitable map.
      // Or the BLoC event could take the full DebtRecord object for update.
      // Let's assume the BLoC event can take the payload.
      // If not, you'd do: context.read<DebtBloc>().add(UpdateDebtRecord(widget.debtRecordToEdit!.id!, debtRecordPayload.toJsonForUpdate()));
      // For now, let's assume UpdateDebtRecord needs to be created in DebtEvent and handled in DebtBloc similar to AddDebtRecord
      print(
        "Dispatching UpdateDebtRecord (Not fully implemented in BLoC/Service example yet)",
      );
      // Example: context.read<DebtBloc>().add(UpdateDebtRecordEvent(widget.debtRecordToEdit!.id!, debtRecordPayload));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update logic needs full BLoC event/handler.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      context.read<DebtBloc>().add(AddDebtRecord(debtRecordPayload));
    }
  }

  Widget _buildItemEntryRow(int index) {
    final entry = _itemEntries[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectProductForItem(index),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Product*',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        entry.selectedProduct?.name ?? 'Tap to select product',
                        style: TextStyle(
                          color:
                              entry.selectedProduct == null
                                  ? Theme.of(context).hintColor
                                  : null,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
                if (entry.selectedProduct != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    tooltip: 'Clear Product Selection',
                    onPressed: () {
                      setState(() {
                        // Reset the item entry, potentially keeping quantity if you want
                        // For full reset of product related fields:
                        String currentQuantity =
                            entry.quantityController.text; // Preserve quantity
                        _itemEntries[index]
                            .dispose(); // Dispose old controllers
                        _itemEntries[index] = _DebtItemEntry(
                          quantity: currentQuantity,
                        ); // New entry, pass preserved qty
                        _calculateGrandTotal();
                      });
                    },
                  ),
                if (_itemEntries.length > 1 ||
                    _isEditing) // Allow removing if editing or more than one item
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Remove This Item',
                    onPressed: () => _removeItemEntry(index),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (entry.selectedProduct != null) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: entry.unitLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Unit?'
                                  : null, // Added validator
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: entry.quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Qty*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Qty?';
                        final dVal = double.tryParse(value);
                        if (dVal == null || dVal <= 0) return 'Invalid';
                        return null;
                      },
                      onChanged: (value) {
                        // This setState will trigger a rebuild, which will call itemSubtotal
                        // and _calculateGrandTotal will update the grand total display.
                        setState(() {
                          _calculateGrandTotal();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: entry.priceAtTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Price/Unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      readOnly: true,
                      validator: (value) {
                        // Added validator
                        if (value == null || value.isEmpty) return 'Price?';
                        final dVal = double.tryParse(value);
                        if (dVal == null || dVal < 0)
                          return 'Invalid'; // Price can be 0
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Subtotal',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(
                          entry.itemSubtotal,
                        ), // This relies on the getter
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (entry.productId != null && entry.selectedProduct == null)
              const Padding(
                // If a productId exists but product details aren't loaded (e.g. edit mode initialization)
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Loading product details or product not found...',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Debt Record' : 'Add New Debt'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Debt (Not Implemented)',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delete not implemented for this form yet.'),
                  ),
                );
              },
            ),
        ],
      ),
      body: BlocListener<DebtBloc, DebtState>(
        listener: (context, state) {
          if (state is DebtOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is DebtError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // Wrap the Form with SingleChildScrollView
          child: SingleChildScrollView(
            // <--- ADD THIS
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Keep items aligned left
                children: [
                  // Customer Info (Display only)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(
                        widget.customer.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        widget.customer.phoneNumber ?? 'No phone number',
                      ),
                    ),
                  ),
                  // const SizedBox(height: 16), // Already handled by Card margin

                  // Debt Date
                  TextFormField(
                    controller: _debtDateController,
                    decoration: const InputDecoration(
                      labelText: 'Debt Date*',
                      hintText: 'Select date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _debtDateController),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select the debt date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Items Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add Item'),
                        onPressed: _addItemEntry,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Items List (This ListView.builder should NOT be wrapped in another Expanded here
                  // because the outer SingleChildScrollView will handle the overall scrolling)
                  if (_itemEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Text(
                          'No items added yet. Click "Add Item".',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap:
                          true, // Crucial for ListView inside SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // Also crucial
                      itemCount: _itemEntries.length,
                      itemBuilder: (context, index) {
                        return _buildItemEntryRow(
                          index,
                        ); // Your existing method
                      },
                    ),

                  const SizedBox(height: 8),
                  // Grand Total (moved from the Row with Add Item for better layout)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Grand Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_grandTotal)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Fields
                  TextFormField(
                    controller: _dueDateController,
                    decoration: const InputDecoration(
                      labelText: 'Due Date (Optional)',
                      hintText: 'Select due date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event_busy),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _dueDateController),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Any additional notes',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                    keyboardType: TextInputType.multiline, // Allow multiline
                    minLines: 1, // Start with 1 line
                    maxLines: 3, // Expand up to 3 lines
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountPaidController,
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid Initially (Optional)',
                      hintText: 'Enter amount if any payment made now',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final val = double.tryParse(value);
                        if (val == null || val < 0) return 'Invalid amount';
                        // We can't validate against _grandTotal here easily if items can still be added/removed
                        // The backend should ideally validate amountPaid <= totalAmount upon submission.
                        // For now, let's remove the grand total check here to avoid complexity during form input.
                        // if (val > _grandTotal) return 'Cannot exceed total';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  BlocBuilder<DebtBloc, DebtState>(
                    builder: (context, state) {
                      if (state is DebtLoading && !state.isFetchingMore) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ElevatedButton.icon(
                        icon: Icon(
                          _isEditing ? Icons.save_alt : Icons.add_task,
                        ),
                        onPressed: _submitForm,
                        label: Text(
                          _isEditing ? 'Update Debt' : 'Save Debt Record',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20), // Add some padding at the bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
