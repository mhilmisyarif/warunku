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
    setState(() {
      _itemEntries[index].dispose(); // Dispose controllers of the removed item
      _itemEntries.removeAt(index);
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    double total = 0;
    for (var entry in _itemEntries) {
      total += entry.itemSubtotal;
    }
    setState(() {
      _grandTotal = total;
    });
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
        context: context, // The context of DebtRecordFormScreen
        builder: (BuildContext dialogContext) {
          // We can provide the ProductBloc to the dialog if it's not already accessible
          // However, ProductSelectionDialog uses context.read<ProductBloc>()
          // which means ProductBloc must be an ancestor of this dialogContext.
          // This should be fine if ProductBloc is provided by MultiBlocProvider in main.dart
          return const ProductSelectionDialog();
        },
      );

      if (result != null) {
        setState(() {
          final entry = _itemEntries[itemIndex];
          entry.selectedProduct = result.product;
          entry.selectedUnit = result.selectedUnit;
          entry.productId = result.product.id;
          entry.productNameController.text = result.product.name;
          entry.unitLabelController.text = result.selectedUnit.label;
          // Use the current selling price from the selected unit as the priceAtTimeOfDebt
          entry.priceAtTimeController.text =
              result.selectedUnit.sellingPrice.toString();
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }
    if (_itemEntries.isEmpty) {
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
      final double quantity =
          double.tryParse(entry.quantityController.text) ?? 0;
      final double priceAtTime =
          double.tryParse(entry.priceAtTimeController.text) ?? 0;

      if (entry.productId == null || entry.productId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product not selected for an item: ${entry.productNameController.text}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (entry.unitLabelController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unit label missing for item: ${entry.productNameController.text}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
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
      if (priceAtTime < 0) {
        // Price can be 0 for free items, but not negative
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Price cannot be negative for item: ${entry.productNameController.text}',
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
                  .productNameController
                  .text, // Could be entry.selectedProduct.name
          unitLabel:
              entry
                  .unitLabelController
                  .text, // Could be entry.selectedUnit.label
          quantity: quantity,
          priceAtTimeOfDebt: priceAtTime,
          totalPrice: quantity * priceAtTime, // Recalculate here to be sure
        ),
      );
    }

    final debtDate =
        DateFormat('yyyy-MM-dd').tryParse(_debtDateController.text) ??
        DateTime.now();
    final dueDate =
        _dueDateController.text.isNotEmpty
            ? DateFormat('yyyy-MM-dd').tryParse(_dueDateController.text)
            : null;
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;

    final debtRecord = DebtRecord(
      // id is not needed for creation
      customer: widget.customer.id!, // Send customer ID
      items: finalItems,
      totalAmount:
          _grandTotal, // Backend will recalculate but good to send estimate
      amountPaid: amountPaid,
      status: 'UNPAID', // Backend will set status based on payment
      debtDate: debtDate,
      dueDate: dueDate,
      notes: _notesController.text.trim(),
    );

    // For editing, the logic would be different, dispatching an UpdateDebtRecord event
    if (_isEditing) {
      // context.read<DebtBloc>().add(UpdateDebtRecord(widget.debtRecordToEdit!.id!, /* map of updated fields */));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Editing not fully implemented yet.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      context.read<DebtBloc>().add(AddDebtRecord(debtRecord));
    }
  }

  Widget _buildItemEntryRow(int index) {
    final entry = _itemEntries[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.selectedProduct?.name ?? 'Select Product',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue),
                  tooltip: 'Select Product',
                  onPressed: () => _selectProductForItem(index),
                ),
                if (_itemEntries.length >
                    1) // Don't allow removing the last item easily
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Remove Item',
                    onPressed: () => _removeItemEntry(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Display selected product details if available
            if (entry.selectedProduct != null)
              TextFormField(
                controller: entry.productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name (Auto-filled)',
                ),
                readOnly: true, // Usually read-only after selection
              ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.unitLabelController,
                    decoration: const InputDecoration(labelText: 'Unit*'),
                    readOnly:
                        entry.selectedUnit !=
                        null, // Read-only if unit selected via dialog
                    validator:
                        (value) =>
                            (value == null || value.isEmpty) ? 'Unit?' : null,
                    onChanged: (_) => _calculateGrandTotal(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: entry.quantityController,
                    decoration: const InputDecoration(labelText: 'Qty*'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Qty?';
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0)
                        return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => _calculateGrandTotal(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.priceAtTimeController,
                    decoration: const InputDecoration(labelText: 'Price/Unit*'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly:
                        entry.selectedUnit !=
                        null, // Read-only if unit selected via dialog
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Price?';
                      if (double.tryParse(value) == null ||
                          double.parse(value) < 0)
                        return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => _calculateGrandTotal(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Subtotal',
                      border: InputBorder.none, // To look like text
                    ),
                    child: Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(entry.itemSubtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
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
            Navigator.of(
              context,
            ).pop(true); // Pop and return true to indicate success
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Customer Info (Display only)
                Card(
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
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                // Items Section
                Text('Items:', style: Theme.of(context).textTheme.titleMedium),
                Expanded(
                  child: ListView.builder(
                    itemCount: _itemEntries.length,
                    itemBuilder: (context, index) {
                      return _buildItemEntryRow(index);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_grandTotal)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                ),

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
                  maxLines: 2,
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
                      if (val > _grandTotal) return 'Cannot exceed total';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                BlocBuilder<DebtBloc, DebtState>(
                  builder: (context, state) {
                    if (state is DebtLoading && !state.isFetchingMore) {
                      // Only show for main operation loading
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.save_alt : Icons.add_task),
                      onPressed: _submitForm,
                      label: Text(
                        _isEditing ? 'Update Debt' : 'Save Debt Record',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ), // Full width
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
