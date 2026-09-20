/// A digitised garment in the user's wardrobe.
class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.status,
    this.brand = '',
    this.colorway = '',
    this.price = 0,
    this.tags = const [],
    this.section = 'TOPS & OUTERWEAR',
  });

  final String id;
  final String name;
  final String category;
  final String image;

  /// Sub-label shown under the name (`EXTRACTED · 3D READY`).
  final String status;
  final String brand;
  final String colorway;
  final double price;
  final List<String> tags;
  final String section;

  WardrobeItem copyWith({
    String? name,
    String? brand,
    String? colorway,
    String? category,
    double? price,
    List<String>? tags,
  }) => WardrobeItem(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    image: image,
    status: status,
    brand: brand ?? this.brand,
    colorway: colorway ?? this.colorway,
    price: price ?? this.price,
    tags: tags ?? this.tags,
    section: section,
  );
}

/// Result of the garment-capture "detection" step.
class GarmentDetection {
  const GarmentDetection({
    required this.label,
    required this.confidence,
    required this.description,
    required this.name,
    required this.category,
    required this.tags,
  });

  final String label;
  final int confidence;
  final String description;
  final String name;
  final String category;
  final List<String> tags;
}
