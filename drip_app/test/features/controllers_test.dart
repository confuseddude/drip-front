import 'package:drip/core/theme/drip_skin.dart';
import 'package:drip/data/models/settings.dart';
import 'package:drip/data/providers.dart';
import 'package:drip/features/bag/bag_controller.dart';
import 'package:drip/features/create/create_ootd_controller.dart';
import 'package:drip/features/home/feed_controller.dart';
import 'package:drip/features/search/search_controller.dart';
import 'package:drip/features/session/session_controller.dart';
import 'package:drip/features/settings/settings_controller.dart';
import 'package:drip/features/social/social_controller.dart';
import 'package:drip/features/studio/studio_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('feed like/save toggle optimistically and update counts', () async {
    final c = await _container();
    final posts = await c.read(feedProvider.future);
    final first = posts.first;
    final likedBefore = first.isLiked;

    await c.read(feedProvider.notifier).toggleLike(first.id);
    final after = c.read(feedProvider).requireValue.first;
    expect(after.isLiked, !likedBefore);
    expect(after.likes, first.likes + (likedBefore ? -1 : 1));

    await c.read(feedProvider.notifier).toggleSave(first.id);
    expect(c.read(feedProvider).requireValue.first.isSaved, !first.isSaved);
  });

  test('settings persist across container restarts', () async {
    final c = await _container();
    await c.read(settingsProvider.notifier).setUsername('new_handle');
    await c.read(settingsProvider.notifier).setPrivate(true);
    await c.read(settingsProvider.notifier).setSkin(DripSkin.auroraCyan);
    await c
        .read(settingsProvider.notifier)
        .setWhoCanInteract(InteractAudience.nobody);

    final prefs = c.read(sharedPreferencesProvider);
    final c2 = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c2.dispose);
    final s = c2.read(settingsProvider);
    expect(s.username, 'new_handle');
    expect(s.privateAccount, isTrue);
    expect(s.skin, DripSkin.auroraCyan);
    expect(s.whoCanInteract, InteractAudience.nobody);
  });

  test('onboarding picks toggle and session lifecycle works', () async {
    final c = await _container();
    expect(c.read(sessionProvider).signedIn, isFalse);
    final before = c.read(onboardingProvider).moodIds.length;
    c.read(onboardingProvider.notifier).toggleMood('preppy');
    expect(c.read(onboardingProvider).moodIds.length, before + 1);
    c.read(onboardingProvider.notifier).toggleMood('preppy');
    expect(c.read(onboardingProvider).moodIds.length, before);

    await c.read(sessionProvider.notifier).completeOnboarding();
    expect(c.read(sessionProvider).signedIn, isTrue);
    await c.read(sessionProvider.notifier).logout();
    expect(c.read(sessionProvider).signedIn, isFalse);
    expect(c.read(sharedPreferencesProvider).getKeys(), isEmpty);
  });

  test('following toggles', () async {
    final c = await _container();
    await c.read(followingSetProvider.future);
    await c.read(followingSetProvider.notifier).toggle('lxna.fits');
    expect(c.read(followingSetProvider).requireValue, contains('lxna.fits'));
    await c.read(followingSetProvider.notifier).toggle('lxna.fits');
    expect(
      c.read(followingSetProvider).requireValue,
      isNot(contains('lxna.fits')),
    );
  });

  test('recent searches: add, de-dupe, cap, remove, persist', () async {
    final c = await _container();
    final n = c.read(recentSearchesProvider.notifier);
    await n.add('Tokyo');
    await n.add('tokyo'); // case-insensitive de-dupe
    expect(
      c.read(recentSearchesProvider).where((e) => e.toLowerCase() == 'tokyo'),
      hasLength(1),
    );
    expect(c.read(recentSearchesProvider).first, 'tokyo');
    for (var i = 0; i < 12; i++) {
      await n.add('q$i');
    }
    expect(c.read(recentSearchesProvider).length, lessThanOrEqualTo(8));
    await n.remove('q11');
    expect(c.read(recentSearchesProvider), isNot(contains('q11')));
    expect(
      c.read(sharedPreferencesProvider).getStringList('search.recents'),
      isNotNull,
    );
  });

  test('bag de-dupes lines and totals', () async {
    final c = await _container();
    final bag = c.read(bagProvider.notifier);
    const a = BagLine(name: 'A', subtitle: 'x', price: 100);
    const b = BagLine(name: 'B', subtitle: 'y', price: 50);
    expect(bag.addAll([a, b]), 2);
    expect(bag.addAll([a]), 0);
    expect(bag.total, 150);
    bag.remove('A');
    expect(bag.total, 50);
  });

  test('studio: select, undo, reset, randomize', () async {
    final c = await _container();
    final s = c.read(studioProvider.notifier);
    final start = c.read(studioProvider).worn['OUTERWEAR']!.id;
    final other = s.piecesFor('OUTERWEAR').firstWhere((p) => p.id != start);
    s.select(other);
    expect(c.read(studioProvider).worn['OUTERWEAR']!.id, other.id);
    s.undo();
    expect(c.read(studioProvider).worn['OUTERWEAR']!.id, start);
    s.select(other);
    s.reset();
    expect(c.read(studioProvider).worn['OUTERWEAR']!.id, 'sp_vest');
    s.randomize();
    expect(c.read(studioProvider).worn, isNotEmpty);
    expect(c.read(studioDripRateProvider), inInclusiveRange(80, 98));
  });

  test('create OOTD tags normalise and a post lands in the feed', () async {
    final c = await _container();
    await c.read(feedProvider.future);
    final n = c.read(createOotdProvider.notifier);
    n.addTag('tech wear');
    expect(c.read(createOotdProvider).tags, contains('#TECHWEAR'));
    n.addTag('#techwear'); // duplicate ignored
    expect(
      c.read(createOotdProvider).tags.where((t) => t == '#TECHWEAR'),
      hasLength(1),
    );
    n.removeTag('#Y2K');
    expect(c.read(createOotdProvider).tags, isNot(contains('#Y2K')));

    final before = c.read(feedProvider).requireValue.length;
    final post = await n.post();
    expect(post, isNotNull);
    final feed = c.read(feedProvider).requireValue;
    expect(feed.length, before + 1);
    expect(feed.first.creatorHandle, 'taylor_drip');
  });
}
