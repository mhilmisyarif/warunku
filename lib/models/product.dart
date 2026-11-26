class ProductUnit {
  final String label;
  final double sellingPrice;

  /// Cost price; null when not recorded.
  final double? purchasePrice;

  /// Units on hand; null when stock is not tracked for this unit.
  final double? stock;

  const ProductUnit({
    required this.label,
    required this.sellingPrice,
    this.purchasePrice,
    this.stock,
  });

  bool get tracksStock => stock != null;
  bool get isOutOfStock => stock != null && stock! <= 0;

  /// Profit per unit sold, when the cost price is known.
  double? get margin =>
      purchasePrice == null ? null : sellingPrice - purchasePrice!;

  factory ProductUnit.fromJson(Map<String, dynamic> json) => ProductUnit(
    label: json['label'] as String? ?? '',
    sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
    purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
    stock: (json['stock'] as num?)?.toDouble(),
  );

  // Null fields are omitted so the backend clears them (unit list is replaced).
  Map<String, dynamic> toJson() => {
    'label': label,
    'sellingPrice': sellingPrice,
    if (purchasePrice != null) 'purchasePrice': purchasePrice,
    if (stock != null) 'stock': stock,
  };
}

class Product {
  /// Empty for a product that has not been saved yet.
  final String id;
  final String name;
  final String description;
  final String category;
  final List<ProductUnit> units;

  /// Path returned by the upload endpoint; resolve with `ApiConstants.imageUrl`.
  final String imagePath;

  const Product({
    this.id = '',
    required this.name,
    this.description = '',
    required this.category,
    required this.units,
    this.imagePath = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    units:
        (json['units'] as List<dynamic>? ?? [])
            .map((u) => ProductUnit.fromJson(u as Map<String, dynamic>))
            .toList(),
    imagePath: json['imagePath'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'units': units.map((unit) => unit.toJson()).toList(),
    'imagePath': imagePath,
  };

  Product copyWith({String? imagePath}) => Product(
    id: id,
    name: name,
    description: description,
    category: category,
    units: units,
    imagePath: imagePath ?? this.imagePath,
  );
}
