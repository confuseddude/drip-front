import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_content.dart';
import '../../data/providers.dart';
import '../../data/repositories/outfit_repository.dart';

/// Recent searches, persisted on the device.
class RecentSearchesController extends Notifier<List<String>> {
  static const _max = 8;

  @override
  List<String> build() =>
      ref.watch(localStoreProvider).recentSearches ??
      List.of(MockContent.seedRecentSearches);

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    state = [
      q,
      ...state.where((e) => e.toLowerCase() != q.toLowerCase()),
    ].take(_max).toList();
    await ref.read(localStoreProvider).setRecentSearches(state);
  }

  Future<void> remove(String query) async {
    state = [
      for (final e in state)
        if (e != query) e,
    ];
    await ref.read(localStoreProvider).setRecentSearches(state);
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(localStoreProvider).setRecentSearches(state);
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesController, List<String>>(
      RecentSearchesController.new,
    );

final trendingVibesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(outfitRepositoryProvider).trendingVibes(),
);

final searchResultsProvider = FutureProvider.family<SearchResults, String>(
  (ref, query) => ref.watch(outfitRepositoryProvider).search(query),
);
