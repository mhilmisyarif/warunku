import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/formatter.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(product.description),
            SizedBox(height: 16),
            Text('Price:', style: Theme.of(context).textTheme.titleMedium),
            ...product.units.map(
              (unit) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${CurrencyFormatter.format(unit.sellingPrice)}/${unit.label}',
                      ),
                      // Text('Stock: ${unit.stock}'),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (product.imagePath.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Image.asset(
                    product.imagePath,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
