import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user.dart';
import '../../data/providers.dart';
import '../../data/repositories/social_repository.dart';

/// Handles the signed-in user follows.
class FollowingController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() =>
      ref.watch(socialRepositoryProvider).followingHandles();

  bool isFollowing(String handle) => state.value?.contains(handle) ?? false;

  Future<void> toggle(String handle) async {
    final current = state.value ?? <String>{};
    final follow = !current.contains(handle);
    final next = {...current};
    follow ? next.add(handle) : next.remove(handle);
    state = AsyncData(next);
    await ref
        .read(socialRepositoryProvider)
        .setFollowing(handle, follow: follow);
  }

  /// Applies a batch of follow / unfollow changes (onboarding "SYNC ALL").
  Future<void> apply({
    required Iterable<String> follow,
    Iterable<String> unfollow = const [],
  }) async {
    final repo = ref.read(socialRepositoryProvider);
    var next = await repo.followMany(follow);
    for (final h in unfollow) {
      next = await repo.setFollowing(h, follow: false);
    }
    state = AsyncData(next);
  }
}

final followingSetProvider =
    AsyncNotifierProvider<FollowingController, Set<String>>(
      FollowingController.new,
    );

final followersPageProvider = FutureProvider<UserPage>(
  (ref) => ref.watch(socialRepositoryProvider).followers(),
);

final followingPageProvider = FutureProvider<UserPage>(
  (ref) => ref.watch(socialRepositoryProvider).following(),
);

final suggestedCreatorsProvider = FutureProvider<List<DripUser>>(
  (ref) => ref.watch(socialRepositoryProvider).suggestedCreators(),
);

final userProvider = FutureProvider.family<DripUser?, String>(
  (ref, handle) => ref.watch(socialRepositoryProvider).user(handle),
);

/// The signed-in user's profile (editable).
class MyProfileController extends AsyncNotifier<DripUser> {
  @override
  Future<DripUser> build() async {
    final me = await ref.watch(socialRepositoryProvider).user('taylor_drip');
    return me!;
  }

  Future<void> saveProfile({String? name, String? bio, String? handle}) async {
    final current = state.value;
    if (current == null) return;
    final next = await ref
        .read(socialRepositoryProvider)
        .updateProfile(current.copyWith(name: name, bio: bio, handle: handle));
    state = AsyncData(next);
  }
}

final myProfileProvider = AsyncNotifierProvider<MyProfileController, DripUser>(
  MyProfileController.new,
);
