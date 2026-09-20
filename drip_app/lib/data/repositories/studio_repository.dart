import '../mock/mock_content.dart';
import '../models/stylist.dart';

/// Studio builder + photoshoot generation.
abstract interface class StudioRepository {
  Future<List<StudioPiece>> pieces(String category);
  int dripRate(Iterable<StudioPiece> worn);

  /// Renders a scene look for [fitName] in [scene]. Returns the image path.
  Future<ShootRender> generateShoot({
    required String fitName,
    required ShootScene scene,
    required ShootMode mode,
  });
}

class ShootRender {
  const ShootRender({
    required this.image,
    required this.title,
    required this.scene,
    required this.score,
  });
  final String image;
  final String title;
  final String scene;
  final int score;
}

class MockStudioRepository implements StudioRepository {
  @override
  Future<List<StudioPiece>> pieces(String category) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return MockContent.studioPieces
        .where((p) => p.category == category)
        .toList();
  }

  @override
  int dripRate(Iterable<StudioPiece> worn) {
    if (worn.isEmpty) return 80;
    // Stable pseudo-score derived from the piece ids.
    final seed = worn.fold<int>(
      0,
      (a, p) => a + p.id.codeUnits.fold(0, (x, c) => x + c),
    );
    return 84 + seed % 15; // 84..98
  }

  @override
  Future<ShootRender> generateShoot({
    required String fitName,
    required ShootScene scene,
    required ShootMode mode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    return ShootRender(
      image: MockContent.shootResult,
      title: '$fitName · ${scene.label}'.toUpperCase(),
      scene: scene.label,
      score: 98,
    );
  }
}
