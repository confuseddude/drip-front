import '../mock/mock_content.dart';
import '../mock/mock_users.dart';
import '../models/user.dart';
import 'local_store.dart';

class UserPage {
  const UserPage({required this.total, required this.users});
  final int total;
  final List<DripUser> users;
}

/// Accounts and the follow graph.
abstract interface class SocialRepository {
  Future<DripUser?> user(String handle);
  Future<UserPage> followers();
  Future<UserPage> following();
  Future<List<DripUser>> suggestedCreators();
  Future<Set<String>> followingHandles();
  Future<Set<String>> setFollowing(String handle, {required bool follow});
  Future<Set<String>> followMany(Iterable<String> handles);
  Future<DripUser> updateProfile(DripUser me);
}

class MockSocialRepository implements SocialRepository {
  MockSocialRepository(this._store)
    : _following = {..._store.following ?? MockContent.seedFollowing};

  final LocalStore _store;
  final Set<String> _following;
  DripUser _me = MockUsers.me;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  Future<DripUser?> user(String handle) async {
    await _latency();
    if (handle == MockUsers.meHandle || handle == _me.handle) return _me;
    for (final u in MockUsers.directory) {
      if (u.handle == handle) return u;
    }
    for (final u in [
      ...MockContent.followers,
      ...MockContent.suggestedCreators,
    ]) {
      if (u.handle == handle) return u;
    }
    return null;
  }

  @override
  Future<UserPage> followers() async {
    await _latency();
    return UserPage(
      total: MockContent.followersTotal,
      users: MockContent.followers,
    );
  }

  @override
  Future<UserPage> following() async {
    await _latency();
    return UserPage(
      total: MockContent.followingTotal,
      users: MockContent.following,
    );
  }

  @override
  Future<List<DripUser>> suggestedCreators() async {
    await _latency();
    return MockContent.suggestedCreators;
  }

  @override
  Future<Set<String>> followingHandles() async => Set.of(_following);

  @override
  Future<Set<String>> setFollowing(
    String handle, {
    required bool follow,
  }) async {
    follow ? _following.add(handle) : _following.remove(handle);
    await _store.setFollowing(_following);
    return Set.of(_following);
  }

  @override
  Future<Set<String>> followMany(Iterable<String> handles) async {
    _following.addAll(handles);
    await _store.setFollowing(_following);
    return Set.of(_following);
  }

  @override
  Future<DripUser> updateProfile(DripUser me) async {
    await _latency();
    _me = me;
    return _me;
  }
}
