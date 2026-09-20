/// Taylor (the AI stylist) blueprint generated from occasion + vibe.
class Blueprint {
  const Blueprint({
    required this.headline,
    required this.banner,
    required this.reasoning,
    required this.drip,
    required this.pieces,
    required this.occasion,
    required this.vibe,
  });

  final String headline;
  final String banner;
  final String reasoning;
  final int drip;
  final List<BlueprintPiece> pieces;
  final String occasion;
  final String vibe;
}

class BlueprintPiece {
  const BlueprintPiece({
    required this.name,
    required this.category,
    required this.price,
    required this.image,
  });

  final String name;
  final String category;
  final int price;
  final String image;
}

/// A scene option in the photoshoot flow.
class ShootScene {
  const ShootScene({required this.id, required this.label, this.image});
  final String id;
  final String label;
  final String? image;
}

enum ShootMode { real, ai, edits }

/// One piece in the studio "swap pieces" carousel.
class StudioPiece {
  const StudioPiece({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    this.price = 0,
  });
  final String id;
  final String name;
  final String category;
  final String image;
  final int price;
}

class MoodTile {
  const MoodTile({required this.id, required this.label, required this.image});
  final String id;
  final String label;
  final String image;
}

class PaletteSwatch {
  const PaletteSwatch({
    required this.id,
    required this.name,
    required this.role,
    required this.hex,
  });
  final String id;
  final String name;
  final String role;
  final int hex;
}
