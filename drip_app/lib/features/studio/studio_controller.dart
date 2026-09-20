import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_content.dart';
import '../../data/models/stylist.dart';
import '../../data/models/wardrobe.dart';
import '../../data/providers.dart';
import '../wardrobe/wardrobe_controller.dart';

/// Studio canvas state: the model wears one piece per category. The history
/// stack powers UNDO; RESET restores the default outfit.
class StudioState {
  const StudioState({
    required this.category,
    required this.worn,
    this.history = const [],
    this.fromWardrobe = false,
  });

  final String category;

  /// Worn piece per category.
  final Map<String, StudioPiece> worn;
  final List<Map<String, StudioPiece>> history;

  /// Whether pieces come from the user's wardrobe instead of the catalogue.
  final bool fromWardrobe;

  int get total => worn.values.fold(0, (s, p) => s + p.price);

  StudioState copyWith({
    String? category,
    Map<String, StudioPiece>? worn,
    List<Map<String, StudioPiece>>? history,
    bool? fromWardrobe,
  }) => StudioState(
    category: category ?? this.category,
    worn: worn ?? this.worn,
    history: history ?? this.history,
    fromWardrobe: fromWardrobe ?? this.fromWardrobe,
  );
}

StudioPiece _catalogue(String id) =>
    MockContent.studioPieces.firstWhere((p) => p.id == id);

/// Wardrobe garment → studio piece.
StudioPiece studioPieceFromWardrobe(WardrobeItem w) => StudioPiece(
  id: 'w:${w.id}',
  name: w.name,
  category: switch (w.category) {
    'Boots' => 'FOOTWEAR',
    'Tops' => 'TOPS',
    _ => 'OUTERWEAR',
  },
  image: w.image,
  price: w.price.round(),
);

class StudioController extends Notifier<StudioState> {
  final _rng = Random();

  @override
  StudioState build() => StudioState(
    category: 'OUTERWEAR',
    worn: {'OUTERWEAR': _catalogue('sp_vest')},
  );

  void setCategory(String c) => state = state.copyWith(category: c);

  void select(StudioPiece piece) {
    if (state.worn[piece.category]?.id == piece.id) return;
    state = state.copyWith(
      worn: {...state.worn, piece.category: piece},
      history: [...state.history, state.worn],
    );
  }

  /// Pieces available for [category] in the current source.
  List<StudioPiece> piecesFor(String category) {
    if (state.fromWardrobe) {
      final items = ref.read(wardrobeProvider).value ?? const <WardrobeItem>[];
      return items
          .map(studioPieceFromWardrobe)
          .where((p) => p.category == category)
          .toList();
    }
    return MockContent.studioPieces
        .where((p) => p.category == category)
        .toList();
  }

  void randomize() {
    final next = <String, StudioPiece>{};
    for (final cat in MockContent.studioCategories) {
      final options = piecesFor(cat);
      if (options.isNotEmpty && (cat == 'OUTERWEAR' || _rng.nextBool())) {
        next[cat] = options[_rng.nextInt(options.length)];
      }
    }
    if (next.isEmpty) return;
    state = state.copyWith(worn: next, history: [...state.history, state.worn]);
  }

  bool get canUndo => state.history.isNotEmpty;

  void undo() {
    if (state.history.isEmpty) return;
    final h = [...state.history];
    final prev = h.removeLast();
    state = state.copyWith(worn: prev, history: h);
  }

  void reset() => state = StudioState(
    category: 'OUTERWEAR',
    worn: {'OUTERWEAR': _catalogue('sp_vest')},
    fromWardrobe: state.fromWardrobe,
  );

  /// Switches the piece source. [wardrobe] starts the canvas from the user's
  /// own garments.
  void useSource({required bool wardrobe}) {
    state = StudioState(
      category: 'OUTERWEAR',
      worn: {'OUTERWEAR': _catalogue('sp_vest')},
      fromWardrobe: wardrobe,
    );
    if (wardrobe) {
      final first = piecesFor('OUTERWEAR');
      if (first.isNotEmpty) {
        state = state.copyWith(worn: {'OUTERWEAR': first.first});
      }
    }
  }
}

final studioProvider = NotifierProvider<StudioController, StudioState>(
  StudioController.new,
);

/// Score for the current studio outfit (0–100).
final studioDripRateProvider = Provider<int>((ref) {
  final s = ref.watch(studioProvider);
  return ref.watch(studioRepositoryProvider).dripRate(s.worn.values);
});
