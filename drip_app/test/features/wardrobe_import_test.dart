import 'dart:io';
import 'dart:typed_data';

import 'package:drip/app.dart';
import 'package:drip/core/platform/notifications.dart';
import 'package:drip/core/utils/format.dart';
import 'package:drip/data/models/wardrobe.dart';
import 'package:drip/data/models/wardrobe_import.dart';
import 'package:drip/data/providers.dart';
import 'package:drip/data/repositories/report_repository.dart';
import 'package:drip/data/repositories/wardrobe_import_repository.dart';
import 'package:drip/features/wardrobe/import/import_controller.dart';
import 'package:drip/features/wardrobe/import/photo_check.dart';
import 'package:drip/features/wardrobe/wardrobe_screen.dart';
import 'package:drip/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';
import '../test_fonts.dart';

PhotoSignals _signals({
  int faces = 1,
  bool person = true,
  double brightness = 0.5,
  int hash = 0,
}) => PhotoSignals(
  faces: faces,
  person: person,
  brightness: brightness,
  hash: hash,
);

/// Stands in for ML Kit: each photo's signals come from its file name.
class _FakeChecker extends PhotoChecker {
  _FakeChecker(this.byName);
  final Map<String, PhotoSignals> byName;

  @override
  Future<PhotoSignals> inspect(String path, Uint8List bytes) async =>
      byName[path.split(Platform.pathSeparator).last]!;

  @override
  Future<void> close() async {}
}

Future<(ProviderContainer, MockReportRepository)> _boot(
  WidgetTester t,
  String path,
) async {
  SharedPreferences.setMockInitialValues({'session.onboarded': true});
  final sp = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(390, 844) * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final reports = MockReportRepository();
  await t.pumpWidget(
    ProviderScope(
      overrides: testOverrides(sp, signedIn: true, reports: reports),
      retry: (_, _) => null,
      child: const DripApp(),
    ),
  );
  final container = ProviderScope.containerOf(
    t.element(find.byType(MaterialApp)),
  );
  await _settle(t, 16);
  container.read(routerProvider).go(path);
  await _settle(t, 10);
  return (container, reports);
}

Future<void> _settle(WidgetTester t, int frames) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets('the import starts with what works best', (t) async {
    await _boot(t, '/wardrobe/import');
    expect(find.text('WELCOME TO YOUR WARDROBE'), findsOneWidget);
    expect(find.text('JUST YOU'), findsOneWidget);
    expect(find.text('MIRROR SELFIES'), findsOneWidget);
    expect(find.text('CHOOSE UP TO 50 PHOTOS'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('the wardrobe sorts by wear and shelves what is not worn', (
    t,
  ) async {
    await _boot(t, '/wardrobe');
    expect(find.text('NOT WORN LATELY'), findsOneWidget);
    expect(find.textContaining('WORN 4×'), findsWidgets);
    await t.tap(find.text('↕ NEWEST'));
    await _settle(t, 3);
    expect(find.text('↕ MOST WORN'), findsOneWidget);
    // Sorted, the grid is one list (and the shelf steps aside).
    expect(find.text('NOT WORN LATELY'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('a bad cut-out is reported in two taps, with the piece', (
    t,
  ) async {
    final (_, reports) = await _boot(t, '/wardrobe/item/w_puff');
    final link = find.text('CUT-OUT LOOK OFF? REPORT IT');
    await t.ensureVisible(link);
    await _settle(t, 2);
    await t.tap(link);
    await _settle(t, 6);
    expect(find.text('Attach this piece'), findsOneWidget);
    await t.tap(find.text('SEND REPORT'));
    await _settle(t, 8);
    final r = reports.sent.single;
    expect(r.kind, 'image');
    expect(r.wardrobeItemId, 'w_puff');
    expect(r.screen, 'wardrobe.item');
    expect(r.message, isNotEmpty);
  });

  group('on-phone checks', () {
    test('judge sets aside groups, empty shots, dark ones and repeats', () {
      expect(judge(_signals(faces: 2), const []), PhotoVerdict.group);
      expect(
        judge(_signals(faces: 0, person: false), const []),
        PhotoVerdict.noPerson,
      );
      // A mirror selfie: the phone hides the face, the body is there.
      expect(judge(_signals(faces: 0), const []), PhotoVerdict.ok);
      expect(judge(_signals(brightness: 0.05), const []), PhotoVerdict.dark);
      final kept = [_signals(hash: 0xFF00FF00FF00FF00)];
      expect(
        judge(_signals(hash: 0xFF00FF00FF00FF03), kept),
        PhotoVerdict.duplicate,
      );
      expect(judge(_signals(hash: 0x00FF00FF00FF00FF), kept), PhotoVerdict.ok);
    });

    test('hamming counts differing bits', () {
      expect(hamming(0, 0), 0);
      expect(hamming(0xF, 0), 4);
      expect(hamming(-1, 0), 64);
    });

    test('EXIF dates parse, junk and future dates do not', () {
      expect(
        parseExifDate('2026:03:12 18:22:10'),
        DateTime(2026, 3, 12, 18, 22, 10),
      );
      expect(parseExifDate('0000:00:00 00:00:00'), isNull);
      expect(parseExifDate('not a date'), isNull);
      expect(parseExifDate('2999:01:01 00:00:00'), isNull);
      expect(parseExifDate(null), isNull);
    });
  });

  group('models', () {
    test('an import reads its progress and summary', () {
      final s = WardrobeImport.fromJson({
        'id': 'imp1',
        'status': 'processing',
        'photosTotal': 20,
        'photosDone': 10,
      });
      expect(s.finished, isFalse);
      expect(s.progress, closeTo(0.47, 0.01));
      final done = s.copyWith(
        status: ImportStatus.done,
        piecesAdded: 12,
        duplicatesMerged: 5,
      );
      expect(done.progress, 1);
      expect(
        importSummary(done),
        '12 new pieces are in your wardrobe. 5 repeats folded together.',
      );
    });

    test('a photo sends only its day', () {
      final p = ImportedPhoto(
        path: 'u/1.jpg',
        takenAt: DateTime(2026, 3, 12, 23, 59),
      );
      expect(p.toJson(), {'path': 'u/1.jpg', 'takenOn': '2026-03-12'});
      expect(const ImportedPhoto(path: 'x').toJson(), {'path': 'x'});
    });

    test('wardrobe items carry their wear history', () {
      final item = WardrobeItem.fromJson({
        'id': 'w1',
        'origin': 'import',
        'status': 'ready',
        'category': 'top',
        'colour': 'black',
        'wearCount': 3,
        'lastWornOn': '2026-09-01',
        'wornOn': ['2026-09-01', '2026-06-10', 'nonsense'],
      });
      expect(item.status, 'FROM YOUR PHOTOS');
      expect(item.wearCount, 3);
      expect(item.lastWornAt, DateTime(2026, 9, 1));
      expect(item.wornOn, [DateTime(2026, 9, 1), DateTime(2026, 6, 10)]);
      // Older payloads simply have none.
      final plain = WardrobeItem.fromJson({'id': 'w2', 'status': 'ready'});
      expect(plain.wearCount, 0);
      expect(plain.wornOn, isEmpty);
    });

    test('days format short this year, with the year otherwise', () {
      final now = DateTime(2026, 10, 21);
      expect(formatDay(DateTime(2026, 3, 12), now: now), '12 Mar');
      expect(formatDay(DateTime(2025, 12, 1), now: now), '1 Dec 2025');
    });
  });

  test('sortWardrobe orders by wear', () {
    WardrobeItem item(String id, int worn, [DateTime? last]) => WardrobeItem(
      id: id,
      name: id,
      category: 'Tops',
      image: '',
      status: '',
      wearCount: worn,
      lastWornAt: last,
    );
    final items = [
      item('a', 2, DateTime(2026, 5)),
      item('b', 9),
      item('c', 2, DateTime(2025, 1)),
      item('d', 0),
    ];
    List<String> ids(WardrobeSort s) => [
      for (final i in sortWardrobe(items, s)) i.id,
    ];
    expect(ids(WardrobeSort.recent), ['a', 'b', 'c', 'd']);
    expect(ids(WardrobeSort.mostWorn).first, 'b');
    expect(ids(WardrobeSort.leastWorn), ['d', 'c', 'a', 'b']);
  });

  group('import flow', () {
    late Directory dir;
    late ProviderContainer container;
    late MockWardrobeImportRepository server;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('drip_import');
      server = MockWardrobeImportRepository(perPhoto: Duration.zero);
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notificationsProvider.overrideWithValue(const NoNotifications()),
          wardrobeImportRepositoryProvider.overrideWithValue(server),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await dir.delete(recursive: true);
    });

    Future<List<String>> photos(List<String> names) async => [
      for (final n in names)
        (await File('${dir.path}${Platform.pathSeparator}$n')
                .writeAsBytes([0xFF, 0xD8, 0xFF]))
            .path,
    ];

    test(
      'checks, uploads the kept photos, then lands in the wardrobe',
      () async {
        final ctrl = container.read(wardrobeImportProvider.notifier);
        final paths = await photos([
          'a.jpg',
          'group.jpg',
          'b.jpg',
          'burst.jpg',
          'dark.jpg',
        ]);
        await ctrl.check(
          paths,
          checker: _FakeChecker({
            'a.jpg': _signals(hash: 0x0F0F0F0F0F0F0F0F),
            'group.jpg': _signals(faces: 3),
            'b.jpg': _signals(hash: 0x00FF00FF00FF00FF),
            'burst.jpg': _signals(hash: 0x0F0F0F0F0F0F0F0E),
            'dark.jpg': _signals(brightness: 0.02, hash: 0x123456789),
          }),
        );
        var run = container.read(wardrobeImportProvider);
        expect(run.phase, ImportPhase.ready);
        expect(run.kept.length, 2);
        expect(
          {for (final (v, n) in run.skipped) v: n},
          {
            PhotoVerdict.group: 1,
            PhotoVerdict.duplicate: 1,
            PhotoVerdict.dark: 1,
          },
        );

        await ctrl.start();
        run = container.read(wardrobeImportProvider);
        expect(run.phase, ImportPhase.processing);
        expect(run.uploaded, 2);
        expect(run.server!.photosTotal, 2);
        final store = container.read(localStoreProvider);
        expect(store.wardrobeImportId, run.server!.id);

        // The stand-in server finishes a moment after the last photo.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await ctrl.tick();
        run = container.read(wardrobeImportProvider);
        expect(run.phase, ImportPhase.done);
        expect(run.server!.piecesAdded, greaterThan(0));
        expect(store.wardrobeImportId, isNull);

        ctrl.dismiss();
        expect(container.read(wardrobeImportProvider).phase, ImportPhase.idle);
      },
    );

    test('says so when the server has no imports yet', () async {
      final unavailable = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          notificationsProvider.overrideWithValue(const NoNotifications()),
          wardrobeImportRepositoryProvider.overrideWithValue(_NoImports()),
        ],
      );
      addTearDown(unavailable.dispose);
      final ctrl = unavailable.read(wardrobeImportProvider.notifier);
      await ctrl.check(
        await photos(['a.jpg']),
        checker: _FakeChecker({'a.jpg': _signals()}),
      );
      await ctrl.start();
      expect(
        unavailable.read(wardrobeImportProvider).phase,
        ImportPhase.unavailable,
      );
      // The preview runs the rest against the stand-in server.
      await ctrl.start(preview: true);
      final run = unavailable.read(wardrobeImportProvider);
      expect(run.preview, isTrue);
      expect(run.phase, ImportPhase.processing);
    });
  });
}

class _NoImports extends MockWardrobeImportRepository {
  @override
  Future<ImportTicket> start(int count) async =>
      throw const ImportUnavailable();
}
