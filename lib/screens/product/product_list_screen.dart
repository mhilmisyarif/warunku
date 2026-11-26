import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/product/product_bloc.dart';
import '../../models/product.dart';
import '../../utils/formatter.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_selection_dialog.dart';
import '../../widgets/search_bar.dart';
import '../cart/cart_screen.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Timer? _debounce;
  String _query = '';
  String? _category; // null = all categories

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _query = query;
      _load();
    });
  }

  void _load() => context.read<ProductBloc>().add(LoadProducts(query: _query));

  Future<void> _refresh() async {
    final bloc = context.read<ProductBloc>()..add(LoadProducts(query: _query));
    await bloc.stream.firstWhere(
      (s) => s is ProductLoaded || s is ProductError,
    );
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _addToCart(Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    final cart = context.read<CartCubit>();
    final unit = await pickUnit(context, product);
    if (unit == null) return;
    // Success needs no snackbar: the cart bar's count and total update, and a
    // floating snackbar would cover that bar.
    if (!cart.add(product, unit)) {
      showResultSnackBar(
        messenger,
        'Stok ${product.name} (${unit.label}) tidak cukup',
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Tambah Produk',
            onPressed: () => _open(const ProductFormScreen()),
          ),
        ],
        bottom: ProductSearchBar(onChanged: _onSearchChanged),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        buildWhen: (_, current) => current.isListState,
        builder: (context, state) {
          return switch (state) {
            ProductLoaded(:final products, :final query) => _buildList(
              products,
              query,
            ),
            ProductError(:final message) => ErrorView(
              message: message,
              onRetry: _load,
            ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
      bottomNavigationBar: _CartBar(onOpen: () => _open(const CartScreen())),
    );
  }

  Widget _buildList(List<Product> products, String query) {
    final categories =
        {
            for (final p in products)
              if (p.category.isNotEmpty) p.category,
          }.toList()
          ..sort();
    // A category that vanished after a search no longer filters anything.
    final category = categories.contains(_category) ? _category : null;
    final shown =
        category == null
            ? products
            : products.where((p) => p.category == category).toList();

    return Column(
      children: [
        if (categories.length > 1)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in categories) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(c),
                    selected: category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child:
                shown.isEmpty
                    ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        EmptyView(
                          icon: Icons.inventory_2_outlined,
                          message:
                              query.isEmpty
                                  ? 'Belum ada produk. Ketuk ikon + di atas untuk menambah.'
                                  : 'Produk "$query" tidak ditemukan.',
                        ),
                      ],
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: shown.length,
                      itemBuilder:
                          (context, index) => ProductCard(
                            product: shown[index],
                            onTap:
                                () => _open(
                                  ProductDetailScreen(product: shown[index]),
                                ),
                            onAdd: () => _addToCart(shown[index]),
                          ),
                    ),
          ),
        ),
      ],
    );
  }
}

/// Cart summary pinned above the tab bar; hidden while the cart is empty.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, List<CartLine>>(
      builder: (context, lines) {
        if (lines.isEmpty) return const SizedBox.shrink();
        final cart = context.read<CartCubit>();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Row(
                children: [
                  Badge(
                    label: Text('${lines.length}'),
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Lihat keranjang')),
                  Text(CurrencyFormatter.format(cart.total)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
