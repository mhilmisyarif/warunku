import 'package:flutter/material.dart';

/// Search field shown under an AppBar title (use as `AppBar.bottom`).
class ProductSearchBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const ProductSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Cari produk...',
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }
}
