import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/product/product_bloc.dart';
import '../../config/api_constants.dart';
import '../../models/product.dart';
import '../../utils/formatter.dart';
import '../../utils/theme.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_selection_dialog.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<ProductBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Hapus produk?'),
            content: Text(
              '${product.name} akan dihapus permanen. Catatan utang dan '
              'penjualan lama tetap menyimpan namanya.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (confirmed == true) bloc.add(DeleteProduct(product.id));
  }

  Future<void> _addToCart(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final cart = context.read<CartCubit>();
    final unit = await pickUnit(context, product);
    if (unit == null) return;
    showResultSnackBar(
      messenger,
      cart.add(product, unit)
          ? '${product.name} (${unit.label}) masuk keranjang'
          : 'Stok ${product.name} (${unit.label}) tidak cukup',
      success: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConstants.imageUrl(product.imagePath);
    final (icon, color) = ProductCard.categoryStyle(product.category);
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final allOutOfStock = product.units.every((u) => u.isOutOfStock);

    final placeholder = Container(
      color: color.withValues(alpha: 0.12),
      child: Center(child: Icon(icon, size: 72, color: color)),
    );

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state is ProductOperationSuccess) {
          showResultSnackBar(messenger, state.message);
          Navigator.pop(context);
        } else if (state is ProductOperationFailure) {
          showResultSnackBar(messenger, state.message, success: false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Produk'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah Produk',
              // Replace this screen so the list shows fresh data after saving.
              onPressed:
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product),
                    ),
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Produk',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          child: FilledButton.icon(
            onPressed: allOutOfStock ? null : () => _addToCart(context),
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(allOutOfStock ? 'Stok habis' : 'Tambah ke keranjang'),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child:
                    imageUrl != null
                        ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => placeholder,
                        )
                        : placeholder,
              ),
            ),
            const SizedBox(height: 20),
            Text(product.name, style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            if (product.category.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(icon, size: 18, color: color),
                  label: Text(product.category),
                ),
              ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(product.description, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 24),
            Text('Harga & stok', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, unit) in product.units.indexed) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withValues(alpha: 0.1),
                        child: Icon(Icons.sell_outlined, color: primary),
                      ),
                      title: Text('Per ${unit.label}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (unit.margin != null)
                            Text(
                              'Modal ${CurrencyFormatter.format(unit.purchasePrice!)}'
                              ' · Untung ${CurrencyFormatter.format(unit.margin!)}',
                            ),
                          if (unit.tracksStock) StockLabel(unit),
                        ],
                      ),
                      trailing: Text(
                        CurrencyFormatter.format(unit.sellingPrice),
                        style: textTheme.titleMedium?.copyWith(color: primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
