import '../mock/mock_content.dart';
import '../models/ootd.dart';

/// Source of the home feed, stories and OOTD interactions.
abstract interface class FeedRepository {
  Future<List<Ootd>> feed();
  Future<List<Story>> stories();
  Future<Ootd?> ootd(String id);
  Future<Ootd> setLiked(String id, {required bool liked});
  Future<Ootd> setSaved(String id, {required bool saved});
  Future<Ootd> publish(Ootd post);
  Future<void> sendReaction(String ootdId, String reaction);
  Future<void> sendMessage(String ootdId, String message);
}

class MockFeedRepository implements FeedRepository {
  final List<Ootd> _feed = List.of(MockContent.feed);

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  Future<List<Ootd>> feed() async {
    await _latency();
    return List.unmodifiable(_feed);
  }

  @override
  Future<List<Story>> stories() async {
    await _latency();
    return MockContent.stories;
  }

  @override
  Future<Ootd?> ootd(String id) async {
    for (final o in _feed) {
      if (o.id == id) return o;
    }
    return null;
  }

  @override
  Future<Ootd> setLiked(String id, {required bool liked}) async {
    final i = _feed.indexWhere((o) => o.id == id);
    final o = _feed[i];
    if (o.isLiked == liked) return o;
    return _feed[i] = o.copyWith(
      isLiked: liked,
      likes: o.likes + (liked ? 1 : -1),
    );
  }

  @override
  Future<Ootd> setSaved(String id, {required bool saved}) async {
    final i = _feed.indexWhere((o) => o.id == id);
    final o = _feed[i];
    if (o.isSaved == saved) return o;
    return _feed[i] = o.copyWith(
      isSaved: saved,
      saves: o.saves + (saved ? 1 : -1),
    );
  }

  @override
  Future<Ootd> publish(Ootd post) async {
    await _latency();
    _feed.insert(0, post);
    return post;
  }

  @override
  Future<void> sendReaction(String ootdId, String reaction) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> sendMessage(String ootdId, String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
