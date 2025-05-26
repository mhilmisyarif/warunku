// lib/widgets/product_selection_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:warunku/blocs/products/product_event.dart';
import 'package:warunku/blocs/products/product_state.dart';
import '../models/product.dart';
import '../blocs/products/product_bloc.dart';

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
  // No need for _products list here if BlocBuilder handles it directly from ProductBloc state

  @override
  void initState() {
    super.initState();
    // Initial fetch if desired, or rely on search
    // If ProductBloc's initial state is ProductLoaded, this isn't strictly needed for empty search
    // context.read<ProductBloc>().add(const SearchProducts("")); // Load all initially or by default
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // No need to setState for _searchTerm if it's only used for dispatching
      context.read<ProductBloc>().add(SearchProducts(query));
    });
  }

  Future<void> _onProductTapped(
    BuildContext dialogPageContext,
    Product product,
  ) async {
    if (product.units.isEmpty) {
      Navigator.of(dialogPageContext).pop(); // Close product selection
      ScaffoldMessenger.of(context).showSnackBar(
        // Use original context for SnackBar
        const SnackBar(
          content: Text('Selected product has no units defined.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ProductUnit? chosenUnit;

    if (product.units.length == 1) {
      chosenUnit = product.units.first;
    } else {
      chosenUnit = await showDialog<ProductUnit?>(
        context:
            dialogPageContext, // Use the context of the current dialog page
        builder:
            (unitDialogContext) => AlertDialog(
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
                        Navigator.of(unitDialogContext).pop(unit);
                      },
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(unitDialogContext).pop(),
                ),
              ],
            ),
      );
    }

    if (chosenUnit != null) {
      // Pop the main ProductSelectionDialog with the result
      Navigator.of(
        dialogPageContext,
      ).pop(ProductSelectionResult(product: product, selectedUnit: chosenUnit));
    }
    // If chosenUnit is null (e.g., unit selection was cancelled), do nothing, dialog remains.
    // Or you could pop with null: Navigator.of(dialogPageContext).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Product'),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
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
                  if (state is ProductLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ProductLoaded) {
                    if (state.products.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }
                    return ListView.builder(
                      itemCount: state.products.length,
                      itemBuilder: (BuildContext context, int index) {
                        final product = state.products[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(product.category),
                          onTap:
                              () => _onProductTapped(
                                this.context,
                                product,
                              ), // Pass AlertDialog's context
                        );
                      },
                    );
                  } else if (state is ProductError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  return const Center(child: Text('Type to search products.'));
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
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
