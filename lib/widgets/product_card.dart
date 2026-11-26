import 'package:flutter/material.dart';
import '../config/api_constants.dart';
import '../models/product.dart';
import '../utils/formatter.dart';
import '../utils/theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  /// Add-to-cart action; no button when null.
  final VoidCallback? onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAdd,
  });

  static (IconData, Color) categoryStyle(String category) => switch (category
      .toLowerCase()) {
    'food' || 'makanan' => (Icons.rice_bowl_rounded, const Color(0xFFE08A1E)),
    'drink' ||
    'beverages' ||
    'minuman' => (Icons.local_drink_rounded, const Color(0xFF2F80ED)),
    'toiletries' ||
    'perlengkapan mandi' => (Icons.soap_rounded, const Color(0xFF9B51E0)),
    'snacks' ||
    'camilan' ||
    'jajanan' => (Icons.cookie_rounded, const Color(0xFF1E9E5A)),
    'cleaning' ||
    'kebersihan' => (Icons.cleaning_services_rounded, const Color(0xFF0E9AA7)),
    _ => (Icons.inventory_2_rounded, const Color(0xFF6B7280)),
  };

  @override
  Widget build(BuildContext context) {
    final firstUnit = product.units.isNotEmpty ? product.units[0] : null;
    final extraUnits = product.units.length - 1;
    final imageUrl = ApiConstants.imageUrl(product.imagePath);
    final (icon, color) = categoryStyle(product.category);
    final textTheme = Theme.of(context).textTheme;
    final allOutOfStock =
        product.units.isNotEmpty && product.units.every((u) => u.isOutOfStock);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  color: color.withValues(alpha: 0.12),
                  child:
                      imageUrl != null
                          ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(icon, color: color),
                          )
                          : Icon(icon, color: color, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    if (product.category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(product.category, style: textTheme.bodySmall),
                    ],
                    if (firstUnit?.tracksStock ?? false) ...[
                      const SizedBox(height: 2),
                      StockLabel(firstUnit!),
                    ],
                  ],
                ),
              ),
              if (firstUnit != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(firstUnit.sellingPrice),
                      style: textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      extraUnits > 0
                          ? '/${firstUnit.label} · +$extraUnits satuan'
                          : '/${firstUnit.label}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              if (onAdd != null) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_shopping_cart),
                  tooltip: 'Tambah ke keranjang',
                  onPressed: allOutOfStock ? null : onAdd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Stok 12 kg", red "Habis" at zero, amber when running low.
class StockLabel extends StatelessWidget {
  const StockLabel(this.unit, {super.key});

  final ProductUnit unit;

  static const lowStock = 5;

  @override
  Widget build(BuildContext context) {
    final stock = unit.stock!;
    final color =
        stock <= 0
            ? AppTheme.danger
            : stock <= lowStock
            ? AppTheme.warning
            : const Color(0xFF6B7280);
    return Text(
      stock <= 0 ? 'Habis' : 'Stok ${formatQuantity(stock)} ${unit.label}',
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
    );
  }
}
