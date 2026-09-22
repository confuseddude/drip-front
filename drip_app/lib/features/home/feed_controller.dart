import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ootd.dart';
import '../../data/providers.dart';

/// The home feed. Likes / saves are applied optimistically and persisted
/// through the repository.
class FeedController extends AsyncNotifier<List<Ootd>> {
  @override
  Future<List<Ootd>> build() => ref.watch(feedRepositoryProvider).feed();

  void _replace(Ootd next) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([for (final o in list) o.id == next.id ? next : o]);
  }

  Future<void> toggleLike(String id) async {
    final current = state.value?.firstWhere((o) => o.id == id);
    if (current == null) return;
    final liked = !current.isLiked;
    _replace(
      current.copyWith(isLiked: liked, likes: current.likes + (liked ? 1 : -1)),
    );
    await ref.read(feedRepositoryProvider).setLiked(id, liked: liked);
  }

  Future<void> toggleSave(String id) async {
    final current = state.value?.firstWhere((o) => o.id == id);
    if (current == null) return;
    final saved = !current.isSaved;
    _replace(
      current.copyWith(isSaved: saved, saves: current.saves + (saved ? 1 : -1)),
    );
    await ref.read(feedRepositoryProvider).setSaved(id, saved: saved);
  }

  Future<void> addComment(String id, String text) async {
    await ref.read(feedRepositoryProvider).addComment(id, text);
    final current = state.value?.where((o) => o.id == id).firstOrNull;
    if (current == null) return;
    _replace(current.copyWith(comments: current.comments + 1));
    ref.invalidate(commentsProvider(id));
  }

  Future<void> share(String id) async {
    await ref.read(feedRepositoryProvider).recordShare(id);
    final current = state.value?.where((o) => o.id == id).firstOrNull;
    if (current == null) return;
    _replace(current.copyWith(shares: current.shares + 1));
  }

  Future<void> publish(Ootd post) async {
    await ref.read(feedRepositoryProvider).publish(post);
    state = AsyncData([post, ...?state.value]);
  }
}

final feedProvider = AsyncNotifierProvider<FeedController, List<Ootd>>(
  FeedController.new,
);

/// Comments for one OOTD (Fashion Scroll comments sheet).
final commentsProvider = FutureProvider.family<List<OotdComment>, String>(
  (ref, id) => ref.watch(feedRepositoryProvider).comments(id),
);

class StoriesController extends AsyncNotifier<List<Story>> {
  @override
  Future<List<Story>> build() => ref.watch(feedRepositoryProvider).stories();

  void markSeen(String handle) {
    final list = state.value;
    if (list == null) return;
    state = AsyncData([
      for (final s in list) s.handle == handle ? s.copyWith(unseen: false) : s,
    ]);
  }
}

final storiesProvider = AsyncNotifierProvider<StoriesController, List<Story>>(
  StoriesController.new,
);

/// Looks up a single post by id from the loaded feed.
final ootdProvider = Provider.family<Ootd?, String>((ref, id) {
  final list = ref.watch(feedProvider).value;
  if (list == null) return null;
  for (final o in list) {
    if (o.id == id) return o;
  }
  return null;
});
