import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/outfit.dart';
import '../../data/providers.dart';

/// Every look in the catalogue (Discover, Search, profile grids, Fit Analysis).
class OutfitCatalogController extends AsyncNotifier<List<Outfit>> {
  @override
  Future<List<Outfit>> build() =>
      ref.watch(outfitRepositoryProvider).discover();

  Future<void> toggleLike(String id) async {
    final list = state.value;
    if (list == null) return;
    final current = list.firstWhere((o) => o.id == id);
    final liked = !current.isLiked;
    state = AsyncData([
      for (final o in list) o.id == id ? o.copyWith(isLiked: liked) : o,
    ]);
    await ref.read(outfitRepositoryProvider).setLiked(id, liked: liked);
  }

  Future<void> add(Outfit look) async {
    await ref.read(outfitRepositoryProvider).publishLook(look);
    state = AsyncData([look, ...?state.value]);
    ref.invalidate(savedOutfitsProvider);
  }
}

final outfitCatalogProvider =
    AsyncNotifierProvider<OutfitCatalogController, List<Outfit>>(
      OutfitCatalogController.new,
    );

final outfitProvider = Provider.family<Outfit?, String>((ref, id) {
  final list = ref.watch(outfitCatalogProvider).value;
  if (list == null) return null;
  for (final o in list) {
    if (o.id == id) return o;
  }
  return null;
});

/// Looks the user has saved (Saved Looks → SAVED STYLES).
class SavedOutfitsController extends AsyncNotifier<List<Outfit>> {
  @override
  Future<List<Outfit>> build() async {
    final saved = await ref.watch(outfitRepositoryProvider).saved();
    // Reflect likes made elsewhere.
    final catalog = ref.watch(outfitCatalogProvider).value ?? const [];
    return [
      for (final s in saved)
        catalog.firstWhere((c) => c.id == s.id, orElse: () => s),
    ];
  }

  bool isSaved(String id) => state.value?.any((o) => o.id == id) ?? false;

  Future<void> toggle(Outfit outfit) async {
    final list = state.value ?? const [];
    final saved = !list.any((o) => o.id == outfit.id);
    state = AsyncData(
      saved
          ? [outfit, ...list]
          : [
              for (final o in list)
                if (o.id != outfit.id) o,
            ],
    );
    await ref.read(outfitRepositoryProvider).setSaved(outfit.id, saved: saved);
  }
}

final savedOutfitsProvider =
    AsyncNotifierProvider<SavedOutfitsController, List<Outfit>>(
      SavedOutfitsController.new,
    );
