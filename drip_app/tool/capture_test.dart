// Dev tool: renders real screenshots of the app (real fonts, assets, blur).
//
//   flutter test tool/capture_test.dart --dart-define=OUT=C:/some/dir
//
// Not part of the shipped app or the regular test run.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drip/app.dart';
import 'package:drip/core/widgets/nav_glyphs.dart';
import 'package:drip/core/theme/drip_skin.dart';
import 'package:drip/data/providers.dart';
import 'package:drip/features/settings/settings_controller.dart';
import 'package:drip/routing/app_router.dart';
import 'package:drip/routing/main_shell.dart' show TabDirection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/test_fonts.dart';

const _out = String.fromEnvironment('OUT', defaultValue: 'build/shots');

final _key = GlobalKey();

Future<void> _settle(WidgetTester t, {int ms = 900}) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final boundary =
        _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final f = File('$_out/$name.png');
    await f.create(recursive: true);
    await f.writeAsBytes(data!.buffer.asUint8List());
  });
}

Future<ProviderContainer> _boot(
  WidgetTester t, {
  Size size = const Size(390, 844),
  DripSkin skin = DripSkin.retroCyber,
}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    'session.signedIn': true,
    'session.onboarded': true,
    'settings.skin': skin.id,
  });
  final sp = await SharedPreferences.getInstance();
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    RepaintBoundary(
      key: _key,
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
        retry: (_, _) => null,
        child: const DripApp(),
      ),
    ),
  );
  return ProviderScope.containerOf(t.element(find.byType(MaterialApp)));
}

Future<void> _loadIcons() async {
  final f = File(
    'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(await f.readAsBytes())));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await _loadIcons();
  });

  testWidgets('splash frames', (t) async {
    final c = await _boot(t);
    // Splash is the initial route.
    await t.pump(const Duration(milliseconds: 250));
    await _shot(t, 'splash_a_250ms');
    await t.pump(const Duration(milliseconds: 350));
    await _shot(t, 'splash_b_600ms');
    await t.pump(const Duration(milliseconds: 250));
    await _shot(t, 'splash_c_850ms');
    c.dispose;
  });

  testWidgets('home + scroll + profile + themes (default skin)', (t) async {
    final c = await _boot(t);
    final router = c.read(routerProvider);
    router.go('/home');
    await _settle(t, ms: 1500);
    await _shot(t, 'home');
    router.go('/scroll');
    await _settle(t, ms: 1200);
    await _shot(t, 'scroll');
    router.go('/me');
    await _settle(t, ms: 1200);
    await _shot(t, 'profile');
    router.push('/themes');
    await _settle(t, ms: 1200);
    await _shot(t, 'themes');
  });

  for (final skin in [
    DripSkin.vaultCream,
    DripSkin.holoPink,
    DripSkin.acidLime,
    DripSkin.denimStars,
  ]) {
    testWidgets('home in ${skin.id}', (t) async {
      final c = await _boot(t, skin: skin);
      c.read(routerProvider).go('/home');
      await _settle(t, ms: 1500);
      await _shot(t, 'home_${skin.id}');
      c.read(routerProvider).go('/scroll');
      await _settle(t, ms: 1200);
      await _shot(t, 'scroll_${skin.id}');
    });
  }

  for (final skin in [
    DripSkin.vaultCream,
    DripSkin.holoPink,
    DripSkin.crimsonTeal,
  ]) {
    testWidgets('profile + settings in ${skin.id}', (t) async {
      final c = await _boot(t, skin: skin);
      c.read(routerProvider).go('/me');
      await _settle(t, ms: 1500);
      await _shot(t, 'profile_${skin.id}');
      c.read(routerProvider).go('/settings');
      await _settle(t, ms: 1200);
      await _shot(t, 'settings_${skin.id}');
    });
  }

  testWidgets('small phone home', (t) async {
    final c = await _boot(t, size: const Size(360, 640));
    c.read(routerProvider).go('/home');
    await _settle(t, ms: 1500);
    await _shot(t, 'home_small_360x640');
    c.read(routerProvider).go('/scroll');
    await _settle(t, ms: 1200);
    await _shot(t, 'scroll_small_360x640');
  });

  testWidgets('comments + share sheets', (t) async {
    final c = await _boot(t);
    c.read(routerProvider).go('/scroll');
    await _settle(t, ms: 1200);
    await t.tap(find.byIcon(Icons.mode_comment_outlined).first);
    await _settle(t, ms: 1000);
    await _shot(t, 'sheet_comments');
    c.read(skinProvider);
  });

  testWidgets('reel glyph sheet', (t) async {
    t.view.physicalSize = const Size(390, 300) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      RepaintBoundary(
        key: _key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: const Color(0xFF141824),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    ReelGlyph(color: Color(0xFF9A9088), size: 30),
                    ReelGlyph(color: Color(0xFFE8DFC8), size: 30, glow: 1),
                    ReelGlyph(color: Color(0xFF9A9088), size: 24),
                    ReelGlyph(color: Color(0xFFE8DFC8), size: 24, glow: 1),
                  ],
                ),
                SizedBox(height: 24),
                ReelGlyph(color: Color(0xFFE8DFC8), size: 200, glow: 0),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await _shot(t, 'glyph_sheet');
  });

  testWidgets('nav lens drag switches tab', (t) async {
    final c = await _boot(t);
    final router = c.read(routerProvider);
    router.go('/home');
    await _settle(t, ms: 1200);
    // Drag on the bar from Home toward Wardrobe (two slots right).
    final start = Offset(390 * 0.20, 844 - 52);
    final g = await t.startGesture(start);
    await t.pump(const Duration(milliseconds: 16));
    for (var i = 1; i <= 10; i++) {
      await g.moveBy(const Offset(14, 0));
      await t.pump(const Duration(milliseconds: 16));
    }
    await _shot(t, 'nav_drag_mid');
    await g.moveBy(const Offset(40, 0));
    await g.up();
    await _settle(t, ms: 900);
    await _shot(t, 'nav_drag_after');
    final loc = router.routeInformationProvider.value.uri.path;
    // ignore: avoid_print
    print('NAV_DRAG_LANDED_ON $loc');
  });

  testWidgets('tab push mid-transition', (t) async {
    final c = await _boot(t);
    final router = c.read(routerProvider);
    router.go('/home');
    await _settle(t, ms: 1500);
    TabDirection.value = 1;
    router.go('/scroll');
    await t.pump();
    await t.pump(const Duration(milliseconds: 90));
    await _shot(t, 'push_mid');
    await _settle(t, ms: 600);
  });

  testWidgets('other screens', (t) async {
    final c = await _boot(t, skin: DripSkin.crimsonTeal);
    final router = c.read(routerProvider);
    for (final r in [
      '/wardrobe',
      '/discover',
      '/activity',
      '/settings',
      '/search',
      '/ootd/ootd_moto',
      '/create',
      '/studio',
      '/outfit/o_cyber_flare',
      '/u/sofiamae',
      '/saved',
    ]) {
      router.go(r);
      await _settle(t, ms: 1100);
      await _shot(t, 'x_${r.replaceAll('/', '_')}');
    }
  });
}
