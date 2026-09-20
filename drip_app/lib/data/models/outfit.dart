/// A complete look: appears in Discover, Search, Saved Looks, profiles and the
/// Fit Analysis screen.
class Outfit {
  const Outfit({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    required this.rate,
    required this.creatorHandle,
    this.tags = const [],
    this.categories = const [],
    this.pieces = const [],
    this.hotspots = const [],
    this.isLiked = false,
  });

  final String id;
  final String title;
  final String image;
  final int price;

  /// Drip rate / score (0–100).
  final int rate;
  final String creatorHandle;
  final List<String> tags;

  /// Discover categories the look belongs to (Y2K, STREET, ...).
  final List<String> categories;
  final List<OutfitPiece> pieces;
  final List<Hotspot> hotspots;
  final bool isLiked;

  int get totalPrice => pieces.fold(0, (sum, p) => sum + p.price);

  Outfit copyWith({bool? isLiked}) => Outfit(
    id: id,
    title: title,
    image: image,
    price: price,
    rate: rate,
    creatorHandle: creatorHandle,
    tags: tags,
    categories: categories,
    pieces: pieces,
    hotspots: hotspots,
    isLiked: isLiked ?? this.isLiked,
  );
}

/// A single garment inside an [Outfit] (Fit Analysis "garment calibration spec").
class OutfitPiece {
  const OutfitPiece({
    required this.slot,
    required this.name,
    required this.brand,
    required this.price,
  });

  /// TOP / BOTTOM / SHOES.
  final String slot;
  final String name;
  final String brand;
  final int price;
}

/// A tappable annotation drawn on the outfit hero image.
class Hotspot {
  const Hotspot({
    required this.label,
    required this.x,
    required this.y,
    this.highlighted = false,
    this.filled = false,
  });

  final String label;

  /// Position as a fraction of the image (0–1).
  final double x;
  final double y;
  final bool highlighted;

  /// Filled pill (active hotspot) vs. outlined text callout.
  final bool filled;
}
