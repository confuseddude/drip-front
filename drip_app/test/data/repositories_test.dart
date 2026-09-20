import 'package:drip/data/mock/mock_users.dart';
import 'package:drip/data/models/wardrobe.dart';
import 'package:drip/data/repositories/local_store.dart';
import 'package:drip/data/repositories/outfit_repository.dart';
import 'package:drip/data/repositories/social_repository.dart';
import 'package:drip/data/repositories/stylist_repository.dart';
import 'package:drip/data/repositories/wardrobe_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

void main() {
  group('OutfitRepository', () {
    test('discover filters by category', () async {
      final repo = MockOutfitRepository();
      final y2k = await repo.discover(category: 'Y2K');
      expect(y2k, isNotEmpty);
      expect(y2k.every((o) => o.categories.contains('Y2K')), isTrue);
      final vintage = await repo.discover(category: 'VINTAGE');
      expect(vintage.map((o) => o.id), isNot(equals(y2k.map((o) => o.id))));
    });

    test('search matches fits and creators; blank query is empty', () async {
      final repo = MockOutfitRepository();
      final r = await repo.search('cyberpunk techwear');
      expect(r.fits, isNotEmpty);
      expect(r.creatorHandles, isNotEmpty);
      final none = await repo.search('   ');
      expect(none.fits, isEmpty);
      final miss = await repo.search('zzzzqqqq');
      expect(miss.total, 0);
    });

    test('search finds accounts by name', () async {
      final r = await MockOutfitRepository().search('sofia');
      expect(r.creatorHandles, contains('sofiamae'));
    });

    test('save toggles the saved list', () async {
      final repo = MockOutfitRepository();
      final before = (await repo.saved()).length;
      await repo.setSaved('o_baggy', saved: true);
      expect((await repo.saved()).length, before + 1);
      await repo.setSaved('o_baggy', saved: false);
      expect((await repo.saved()).length, before);
    });
  });

  group('SocialRepository', () {
    test('follow state persists to the local store', () async {
      final store = await _store();
      final repo = MockSocialRepository(store);
      expect(await repo.followingHandles(), isNot(contains('lxna.fits')));
      await repo.setFollowing('lxna.fits', follow: true);
      expect(await repo.followingHandles(), contains('lxna.fits'));
      // A new repository (app restart) reads the persisted set.
      final reborn = MockSocialRepository(store);
      expect(await reborn.followingHandles(), contains('lxna.fits'));
    });

    test('resolves users and reports unknown handles as null', () async {
      final repo = MockSocialRepository(await _store());
      expect((await repo.user('sofiamae'))?.name, 'Sofia Mae');
      expect(await repo.user('nobody_here'), isNull);
      expect((await repo.user(MockUsers.meHandle))?.name, 'Taylor Vance');
    });
  });

  group('WardrobeRepository', () {
    test('add, update and remove', () async {
      final repo = MockWardrobeRepository();
      final start = (await repo.items()).length;
      const item = WardrobeItem(
        id: 'w_test',
        name: 'Test Coat',
        category: 'Outerwear',
        image: 'assets/images/wardrobe_crop_puff.jpg',
        status: 'EXTRACTED',
      );
      await repo.add(item);
      expect((await repo.items()).first.id, 'w_test');
      await repo.update(item.copyWith(name: 'Renamed'));
      expect((await repo.byId('w_test'))?.name, 'Renamed');
      await repo.remove('w_test');
      expect((await repo.items()).length, start);
      expect(await repo.byId('w_test'), isNull);
    });
  });

  group('StylistRepository', () {
    test('restricts to wardrobe pieces when asked', () async {
      final wardrobe = await MockWardrobeRepository().items();
      final bp = await MockStylistRepository().generateBlueprint(
        occasion: 'Concert',
        vibe: 'Experimental Cyber',
        restrictToWardrobe: true,
        wardrobe: wardrobe,
      );
      expect(
        bp.pieces.map((p) => p.name),
        everyElement(isIn(wardrobe.map((w) => w.name))),
      );
      expect(bp.drip, inInclusiveRange(90, 98));
    });
  });
}
