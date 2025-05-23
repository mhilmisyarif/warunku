class ProductUnit {
  final String label;
  // final double purchasePrice;
  final double sellingPrice;
  // final int stock;

  ProductUnit({
    required this.label,
    // required this.purchasePrice,
    required this.sellingPrice,
    // required this.stock,
  });
  Map<String, dynamic> toJson() => {
    'label': label,
    // 'purchasePrice': purchasePrice,
    'sellingPrice': sellingPrice,
    // 'stock': stock,
  };
  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      label: json['label'],
      // purchasePrice: (json['purchasePrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      // stock: json['stock'],
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<ProductUnit> units;
  final String imagePath;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.units,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'units': units.map((unit) => unit.toJson()).toList(),
    'imagePath': imagePath,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      units:
          (json['units'] as List).map((u) => ProductUnit.fromJson(u)).toList(),
      imagePath: json['imagePath'],
    );
  }
}
