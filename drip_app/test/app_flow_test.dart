import 'package:drip/app.dart';
import 'package:drip/core/widgets/brand.dart';
import 'package:drip/core/widgets/tap.dart';
import 'package:drip/data/providers.dart';
import 'package:drip/features/home/feed_controller.dart';
import 'package:drip/features/session/session_controller.dart';
import 'package:drip/features/settings/settings_controller.dart';
import 'package:drip/features/social/social_controller.dart';
import 'package:drip/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_fonts.dart';

/// Pumps in small steps: the app has looping animations, so `pumpAndSettle`
/// would never return.
Future<void> settle(WidgetTester t, [int ms = 700]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapText(WidgetTester t, String text, {bool warn = true}) async {
  final f = find.text(text);
  expect(f, findsWidgets, reason: 'expected to find "$text"');
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: warn);
  await settle(t);
}

void main() {
  late ProviderContainer container;

  setUpAll(loadAppFonts);

  Future<void> boot(
    WidgetTester t, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
        retry: (_, _) => null,
        child: const DripApp(),
      ),
    );
    container = ProviderScope.containerOf(t.element(find.byType(MaterialApp)));
  }

  testWidgets('onboarding → home → like → discover → settings → logout', (
    t,
  ) async {
    await boot(t);

    // Splash runs its launch sequence, then lands on the welcome screen.
    expect(find.byType(DripWordmark), findsOneWidget);
    await settle(t, 3200);
    expect(find.text('THE FIT FINDS YOU.'), findsOneWidget);

    // Onboarding.
    await tapText(t, 'GET STARTED →');
    expect(find.text('WHAT IS DRIP?'), findsOneWidget);
    await tapText(t, 'UNDERSTOOD. NEXT →');
    expect(find.text('STYLE QUIZ'), findsOneWidget);

    // Deselect every era → CONFIRM must refuse to continue.
    for (final era in ['Y2K', 'Streetwear', 'Techwear']) {
      await tapText(t, era);
    }
    expect(container.read(onboardingProvider).moodIds, isEmpty);
    await tapText(t, 'CONFIRM ERA →');
    expect(
      find.text('STYLE QUIZ'),
      findsOneWidget,
      reason: 'needs at least one era',
    );
    await tapText(t, 'Minimal');
    await tapText(t, 'CONFIRM ERA →');

    expect(find.text('COLOUR THEORY'), findsOneWidget);
    await tapText(t, 'CALIBRATE SPECTRUM →');
    expect(find.text('FOLLOW THE CORE'), findsOneWidget);

    // Follow one creator; the pass reflects the picks.
    await tapText(t, 'FOLLOW');
    expect(
      container.read(followingSetProvider).requireValue,
      contains('lxna.fits'),
    );
    await tapText(t, 'SKIP');
    expect(find.text('WELCOME TO THE VIBE.'), findsOneWidget);
    expect(find.text('MINIMAL'), findsOneWidget);
    await tapText(t, 'ENTER DRIP ✦');
    await settle(t, 1200);

    // Home feed.
    expect(container.read(sessionProvider).signedIn, isTrue);
    expect(find.text('Your story'), findsOneWidget);
    expect(find.text('FRESH FITS'), findsOneWidget);
    expect(find.text('ASK TAYLOR  →'), findsOneWidget);

    // Like the first fit in the Fashion Scroll, then come back Home.
    final before = container.read(feedProvider).requireValue.first;
    container.read(routerProvider).go('/scroll');
    await settle(t, 900);
    await t.tap(
      find
          .byWidgetPredicate(
            (w) =>
                w is Tap &&
                w.semanticLabel == (before.isLiked ? 'Unlike' : 'Like'),
          )
          .first,
    );
    await settle(t);
    expect(
      container.read(feedProvider).requireValue.first.isLiked,
      !before.isLiked,
    );
    container.read(routerProvider).go('/home');
    await settle(t, 900);

    // Discover filters by category.
    await tapText(t, 'SEARCH & DISCOVER  →');
    await settle(t, 800);
    expect(find.text('PASTEL SHOCK'), findsOneWidget);
    await tapText(t, 'GRUNGE');
    expect(find.text('PASTEL SHOCK'), findsNothing);
    expect(find.text('BAGGY ERA FIT'), findsOneWidget);

    // Settings: toggles persist, skin recolours, logout returns to welcome.
    container.read(routerProvider).go('/settings');
    await settle(t, 1200);
    expect(find.text('SETTINGS'), findsOneWidget);
    final push = container.read(settingsProvider).pushNotifications;
    await t.scrollUntilVisible(
      find.text('Push Notifications'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('Push Notifications'));
    // Tapping the label does nothing: only the switch toggles.
    await settle(t);
    expect(container.read(settingsProvider).pushNotifications, push);
    await container.read(settingsProvider.notifier).setPush(!push);
    expect(
      container.read(sharedPreferencesProvider).getBool('settings.push'),
      !push,
    );

    await t.scrollUntilVisible(
      find.text('LOG OUT OF DRIP'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapText(t, 'LOG OUT OF DRIP');
    expect(find.text('LOG OUT?'), findsOneWidget);
    await tapText(t, 'LOG OUT');
    await settle(t, 1200);
    expect(container.read(sessionProvider).signedIn, isFalse);
    expect(find.text('THE FIT FINDS YOU.'), findsOneWidget);
    expect(container.read(sharedPreferencesProvider).getKeys(), isEmpty);
  });

  testWidgets('signed-in users skip onboarding; guards protect app routes', (
    t,
  ) async {
    await boot(t, prefs: {'session.signedIn': true, 'session.onboarded': true});
    await settle(t, 3200);
    expect(find.text('Your story'), findsOneWidget);
  });

  testWidgets(
    'signed-out users are redirected to welcome from protected routes',
    (t) async {
      await boot(t);
      await settle(t, 3200);
      container.read(routerProvider).go('/wardrobe');
      await settle(t, 800);
      expect(find.text('THE FIT FINDS YOU.'), findsOneWidget);
    },
  );
}
