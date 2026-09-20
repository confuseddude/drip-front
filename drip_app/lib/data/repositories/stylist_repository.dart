import '../mock/mock_content.dart';
import '../models/stylist.dart';
import '../models/wardrobe.dart';

/// Taylor, the AI stylist. Mock logic is deterministic so the UI is testable;
/// the real implementation will call the stylist API.
abstract interface class StylistRepository {
  Future<Blueprint> generateBlueprint({
    required String occasion,
    required String vibe,
    required bool restrictToWardrobe,
    required List<WardrobeItem> wardrobe,
  });
}

class MockStylistRepository implements StylistRepository {
  @override
  Future<Blueprint> generateBlueprint({
    required String occasion,
    required String vibe,
    required bool restrictToWardrobe,
    required List<WardrobeItem> wardrobe,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    final pieces = restrictToWardrobe && wardrobe.isNotEmpty
        ? [
            for (final w in wardrobe.take(3))
              BlueprintPiece(
                name: w.name,
                category: w.category.toUpperCase(),
                price: w.price.round(),
                image: w.image,
              ),
          ]
        : [
            BlueprintPiece(
              name: 'Cyber Shell Overcoat',
              category: 'OUTERWEAR',
              price: 189,
              image: MockContent.taylorOvercoat,
            ),
            const BlueprintPiece(
              name: 'Chrome Cargo Loose Track Pants',
              category: 'BOTTOMS',
              price: 110,
              image: 'assets/images/result_neo_cargo.jpg',
            ),
            const BlueprintPiece(
              name: 'Platform Heavy Boots v2',
              category: 'FOOTWEAR',
              price: 220,
              image: 'assets/images/wardrobe_chunky_boots.jpg',
            ),
          ];

    final score = 90 + ((occasion.length + vibe.length) % 9);
    return Blueprint(
      headline: "I'D WEAR\nTHIS.",
      banner: MockContent.taylorBanner,
      reasoning:
          'The ${pieces.first.name.toLowerCase()} anchors the $vibe silhouette, balanced by heavy hardware '
          'below. Built for $occasion: waterproof utility up top, comfortable structure underneath.',
      drip: score,
      pieces: pieces,
      occasion: occasion,
      vibe: vibe,
    );
  }
}
