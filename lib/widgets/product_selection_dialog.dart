import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:warunku/blocs/products/product_event.dart';
import 'package:warunku/blocs/products/product_state.dart';
import '../models/product.dart';
import '../blocs/products/product_bloc.dart'; // Assuming you use ProductBloc for searching

// Data class to return selected product and unit
class ProductSelectionResult {
  final Product product;
  final ProductUnit selectedUnit;

  ProductSelectionResult({required this.product, required this.selectedUnit});
}

class ProductSelectionDialog extends StatefulWidget {
  const ProductSelectionDialog({super.key});

  @override
  State<ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> {
  String _searchTerm = '';
  Timer? _debounce;
  List<Product> _products = []; // To hold the search results

  @override
  void initState() {
    super.initState();
    // Initial load or search if needed, or search as user types
    // For simplicity, we'll load based on search term changes.
    // Ensure ProductBloc is provided above the context where this dialog is shown.
    // Or, fetch initially with an empty search term.
    _fetchProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchProducts() {
    // Using ProductBloc from context
    context.read<ProductBloc>().add(
      SearchProducts(_searchTerm),
    ); // Dispatch search event
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchTerm = query;
      });
      _fetchProducts();
    });
  }

  Future<void> _onProductSelected(
    BuildContext dialogContext,
    Product product,
  ) async {
    if (product.units.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Selected product has no units defined.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (product.units.length == 1) {
      // If only one unit, select it automatically
      Navigator.of(dialogContext).pop(
        ProductSelectionResult(
          product: product,
          selectedUnit: product.units.first,
        ),
      );
    } else {
      // Let user pick a unit
      final selectedUnit = await showDialog<ProductUnit?>(
        context: dialogContext, // Use the dialog's context
        builder:
            (context) => AlertDialog(
              title: Text('Select Unit for ${product.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: product.units.length,
                  itemBuilder: (BuildContext context, int index) {
                    final unit = product.units[index];
                    return ListTile(
                      title: Text(unit.label),
                      subtitle: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(unit.sellingPrice),
                      ),
                      onTap: () {
                        Navigator.of(context).pop(unit);
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );

      if (selectedUnit != null) {
        Navigator.of(dialogContext).pop(
          ProductSelectionResult(product: product, selectedUnit: selectedUnit),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This dialog will be shown using showDialog, so it gets its own context.
    return AlertDialog(
      title: const Text('Select Product'),
      content: SizedBox(
        width: double.maxFinite, // Make dialog wider
        height: MediaQuery.of(context).size.height * 0.6, // Adjust height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Products',
                hintText: 'Type product name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading && _products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ProductLoaded) {
                    // Update local list if the state's products are different
                    // This simplistic check might need refinement based on how search is triggered
                    _products = state.products;
                  } else if (state is ProductError && _products.isEmpty) {
                    return Center(child: Text('Error: ${state.message}'));
                  }

                  if (_products.isEmpty && _searchTerm.isNotEmpty) {
                    return const Center(
                      child: Text('No products found for your search.'),
                    );
                  } else if (_products.isEmpty) {
                    return const Center(
                      child: Text('Type to search products.'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: _products.length,
                    itemBuilder: (BuildContext context, int index) {
                      final product = _products[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(product.category),
                        onTap:
                            () => _onProductSelected(
                              this.context,
                              product,
                            ), // Pass this.context (AlertDialog's context)
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog, returning null
          },
        ),
      ],
    );
  }
}
