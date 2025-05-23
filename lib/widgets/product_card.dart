import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/formatter.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({Key? key, required this.product, required this.onTap})
    : super(key: key);

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'drink':
      case 'beverages':
        return Icons.local_drink;
      case 'toiletries':
        return Icons.soap;
      case 'snacks':
        return Icons.emoji_food_beverage;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.category;
    }
  }

  Color _getIconColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'drink':
      case 'beverages':
        return Colors.blue;
      case 'toiletries':
        return Colors.purple;
      case 'snacks':
        return Colors.green;
      case 'cleaning':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstUnit = product.units.isNotEmpty ? product.units[0] : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  product.imagePath.isNotEmpty
                      ? NetworkImage(product.imagePath)
                      : null,
              child:
                  product.imagePath.isEmpty
                      ? Icon(
                        _getIconForCategory(product.category),
                        color: _getIconColorForCategory(product.category),
                        size: 28,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (product.category.isNotEmpty)
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (firstUnit != null)
              Row(
                children: [
                  Text(
                    '${CurrencyFormatter.format(firstUnit.sellingPrice)}/${firstUnit.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
