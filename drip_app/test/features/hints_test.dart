import 'package:drip/app.dart';
import 'package:drip/features/hints/hints.dart';
import 'package:drip/features/scroll/fashion_scroll_screen.dart';
import 'package:drip/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';
import '../test_fonts.dart';

/// Tips show up one at a time, where the feature is, the first time the user
/// comes across it: never a tour in one go, never in the way.
void main() {
  setUpAll(loadAppFonts);

  late ProviderContainer container;
  late SharedPreferences prefs;

  String text(String id) => hints.firstWhere((h) => h.id == id).text;

  Future<void> settle(WidgetTester t, [int ms = 1000]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> boot(WidgetTester t, {List<String> seen = const []}) async {
    SharedPreferences.setMockInitialValues({
      'session.onboarded': true,
      'hints.seen': seen,
    });
    prefs = await SharedPreferences.getInstance();
    t.view.physicalSize = const Size(390, 844) * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: testOverrides(prefs, signedIn: true, hints: true),
        retry: (_, _) => null,
        child: const DripApp(),
      ),
    );
    container = ProviderScope.containerOf(t.element(find.byType(MaterialApp)));
  }

  void go(String path) => container.read(routerProvider).go(path);

  testWidgets('Home shows one small tip, after a moment, and nothing else', (
    t,
  ) async {
    await boot(t);
    await settle(t, 600);
    expect(find.text(text('home.camera')), findsNothing); // not at once
    await settle(t, 3400);
    expect(find.text(text('home.camera')), findsOneWidget);
    // Only that one: the other Home tips wait for later visits.
    expect(find.text(text('home.tools')), findsNothing);
    expect(find.text(text('nav.swipe')), findsNothing);
  });

  testWidgets("a touch anywhere puts it away and still does what it touched", (
    t,
  ) async {
    await boot(t);
    await settle(t, 4000);
    expect(find.text(text('home.camera')), findsOneWidget);

    // Tap the Scroll tab: the tip goes, and the tab opens.
    await t.tap(find.bySemanticsLabel(RegExp('Scroll')).last);
    await settle(t, 800);
    expect(find.text(text('home.camera')), findsNothing);
    expect(find.byType(FashionScrollScreen), findsOneWidget);
    expect(prefs.getStringList('hints.seen'), contains('home.camera'));
  });

  testWidgets('a tip shows once; the next one waits for the next visit', (
    t,
  ) async {
    await boot(t);
    await settle(t, 4000);
    await t.tap(find.text(text('home.camera'))); // tap the bubble to close
    await settle(t, 9000);
    // Still the same visit to Home: nothing more.
    expect(find.text(text('home.camera')), findsNothing);
    expect(find.text(text('home.tools')), findsNothing);

    go('/studio');
    await settle(t, 4000);
    expect(find.text(text('studio.new')), findsOneWidget);
    await t.tap(find.text(text('studio.new')));
    await settle(t, 6000);

    go('/home');
    await settle(t, 4000);
    expect(find.text(text('home.camera')), findsNothing);
    expect(find.text(text('home.tools')), findsOneWidget);
  });

  testWidgets('left alone, a tip fades by itself and counts as seen', (
    t,
  ) async {
    await boot(t);
    await settle(t, 4000);
    expect(find.text(text('home.camera')), findsOneWidget);
    await settle(t, 9500);
    expect(find.text(text('home.camera')), findsNothing);
    expect(prefs.getStringList('hints.seen'), contains('home.camera'));
  });

  testWidgets('seen tips stay away; Settings brings them back', (t) async {
    await boot(t, seen: [for (final h in hints) h.id]);
    await settle(t, 4000);
    expect(find.text(text('home.camera')), findsNothing);

    await container.read(hintsProvider.notifier).reset();
    go('/studio');
    await settle(t, 4000);
    expect(find.text(text('studio.new')), findsOneWidget);
  });
}
