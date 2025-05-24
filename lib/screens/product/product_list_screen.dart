import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar.dart';

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

  // Create an instance of ProductService
  final ProductService _productService = ProductService(); // NEW INSTANCE

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
      // CORRECTED WAY: Call the method on the instance
      final data = await _productService.getAllProducts(
        searchTerm: searchQuery,
      ); // Pass search query
      // Note: I've assumed getAllProducts now takes an optional searchTerm.
      // Adjust if your ProductService.getAllProducts signature is different.
      // If it doesn't take a searchTerm, you'll filter locally *after* fetching all products.

      if (!mounted) return; // Check mounted again after await
      setState(() {
        products = data;
        // Apply local filtering if `getAllProducts` doesn't filter on backend
        // or if you want to refine search on already fetched data
        if (searchQuery.isEmpty) {
          filteredProducts = List.from(products);
        } else {
          _filterProductsLocally(); // Call the local filter method
        }
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$_errorFetchingProductsText$e')));
    }
  }

  void _filterProductsLocally() {
    if (searchQuery.isEmpty) {
      filteredProducts = List.from(products);
    } else {
      filteredProducts =
          products
              .where(
                (product) => product.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }
  }

  void navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen()),
    );
    if (result == true && mounted) {
      fetchProducts(); // Re-fetch products or only the affected ones
    }
  }

  void navigateToDetail(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
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
        // Option 1: Re-fetch from backend with search term
        fetchProducts();

        // Option 2: If you prefer local filtering after an initial full fetch
        // _filterProductsLocally();
        // if (products.isNotEmpty && query.isNotEmpty) {
        //   _filterProductsLocally();
        // } else if (query.isEmpty) {
        //    filteredProducts = List.from(products);
        // }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ProductSearchBar(onChanged: updateSearchQuery),
        // backgroundColor: Theme.of(context).primaryColor, // Assuming this comes from your theme
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty && searchQuery.isNotEmpty
              ? Center(child: Text('No products found for "$searchQuery".'))
              : filteredProducts.isEmpty &&
                  products
                      .isNotEmpty // No search query but still no filtered results (should not happen if filter logic is correct)
              ? const Center(child: Text(_noProductsFoundText))
              : products
                  .isEmpty // No products at all
              ? const Center(
                child: Text('No products available.'),
              ) // More specific message
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
