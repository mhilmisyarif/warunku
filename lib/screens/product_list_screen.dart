import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import '../services/api_services.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';

import 'dart:async';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  String searchQuery = '';
  Timer? _debounce;

  static const String _noProductsFoundText = 'No products found.';
  static const String _errorFetchingProductsText = 'Error fetching products: ';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final data = await ProductService.getAllProducts();
      setState(() {
        products = data;
        filteredProducts = data; // Initialize filtered list
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$_errorFetchingProductsText$e')));
    }
  }

  void navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen()),
    );
    // If ProductFormScreen pops with `true`, it means data might have changed
    if (result == true && mounted) {
      fetchProducts();
    }
  }

  void navigateToDetail(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
    // If ProductDetailScreen pops with `true`, it means data might have changed
    if (result == true && mounted) {
      fetchProducts();
    }
  }

  void updateSearchQuery(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        searchQuery = query;
        if (query.isEmpty) {
          filteredProducts = List.from(products);
        } else {
          filteredProducts =
              products
                  .where(
                    (product) => product.name.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ProductSearchBar(onChanged: updateSearchQuery),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
              ? const Center(child: Text('$_noProductsFoundText'))
              : RefreshIndicator(
                onRefresh: fetchProducts,
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: filteredProducts[index],
                      onTap: () => navigateToDetail(filteredProducts[index]),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
