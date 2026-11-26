import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/formatter.dart';
import 'product_card.dart';

class ProductSelectionResult {
  final Product product;
  final ProductUnit selectedUnit;

  const ProductSelectionResult({
    required this.product,
    required this.selectedUnit,
  });
}

/// Asks which unit of [product] to use; skips the question when there is
/// only one. Out-of-stock units can't be picked. Null when cancelled.
Future<ProductUnit?> pickUnit(BuildContext context, Product product) async {
  if (product.units.length == 1) return product.units.first;
  return showDialog<ProductUnit>(
    context: context,
    builder:
        (dialogContext) => SimpleDialog(
          title: Text('Pilih satuan ${product.name}'),
          children: [
            for (final unit in product.units)
              SimpleDialogOption(
                onPressed:
                    unit.isOutOfStock
                        ? null
                        : () => Navigator.pop(dialogContext, unit),
                child: Text(
                  '${unit.label} — ${CurrencyFormatter.format(unit.sellingPrice)}'
                  '${unit.isOutOfStock ? ' (habis)' : ''}',
                  style: TextStyle(
                    color:
                        unit.isOutOfStock
                            ? Theme.of(context).disabledColor
                            : null,
                  ),
                ),
              ),
          ],
        ),
  );
}

/// Lets the user search for a product and pick one of its units.
/// Searches on its own so it never disturbs the shared product list.
class ProductSelectionDialog extends StatefulWidget {
  const ProductSelectionDialog({super.key});

  @override
  State<ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> {
  Timer? _debounce;
  late Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<Product>> _search(String query) =>
      context.read<ProductService>().getProducts(searchTerm: query);

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _products = _search(query));
    });
  }

  Future<void> _onProductTapped(Product product) async {
    if (product.units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk ini belum punya satuan.')),
      );
      return;
    }

    final unit = await pickUnit(context, product);
    if (unit != null && mounted) {
      Navigator.pop(
        context,
        ProductSelectionResult(product: product, selectedUnit: unit),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Produk'),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari produk',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _products,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = snapshot.data!;
                  if (products.isEmpty) {
                    return const Center(child: Text('Produk tidak ditemukan.'));
                  }
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final (icon, color) = ProductCard.categoryStyle(
                        product.category,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(product.name),
                        subtitle: Text(product.category),
                        trailing:
                            product.units.isEmpty
                                ? null
                                : Text(
                                  CurrencyFormatter.format(
                                    product.units.first.sellingPrice,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        onTap: () => _onProductTapped(product),
                      );
                    },
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
