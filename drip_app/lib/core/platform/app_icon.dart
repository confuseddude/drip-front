import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_controller.dart';
import '../theme/drip_skin.dart';

/// Sets the launcher icon. The icon for a theme is that theme's poster
/// (Android: one `<activity-alias>` per theme; iOS: one alternate icon set per
/// theme; the default theme is the primary icon).
abstract interface class AppIconService {
  Future<void> setIcon(DripSkin skin);
}

/// Talks to the native side over the `drip/app_icon` channel (see
/// `MainActivity.kt` and `AppDelegate.swift`). A no-op where launcher icons
/// can't change (web, desktop, tests), and failures are swallowed: a missing
/// icon swap must never affect the app.
class ChannelAppIconService implements AppIconService {
  static const _channel = MethodChannel('drip/app_icon');

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> setIcon(DripSkin skin) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('setIcon', {
        'id': skin.asset,
        'isDefault': skin == DripSkin.retroCyber,
        'all': [for (final s in DripSkin.values) s.asset],
      });
    } on PlatformException catch (e) {
      debugPrint('App icon not changed: ${e.message}');
    } on MissingPluginException {
      // Native side not present (e.g. running in a host without the channel).
    }
  }
}

final appIconServiceProvider = Provider<AppIconService>(
  (ref) => ChannelAppIconService(),
);

/// Keeps the launcher icon in step with the saved theme.
///
/// **When** the swap happens matters. On Android, switching the launcher
/// `<activity-alias>` can make the system restart the app's process even with
/// `DONT_KILL_APP` (several vendors' launchers do), which looked like the app
/// crashing right after a theme change. So on Android the swap waits until the
/// app goes to the background, where a restart is invisible; the choice is
/// already saved, so nothing is lost. iOS can only change the icon while the
/// app is in the foreground (and never restarts it), so there it is debounced
/// instead, letting flicking through themes change the icon once, when you
/// stop. Preview-only browsing in the picker never touches the icon. Turn
/// "Match app icon" off and the default icon returns.
final appIconSyncProvider = Provider<void>((ref) {
  final binding = WidgetsBinding.instance;
  final deferToBackground = defaultTargetPlatform != TargetPlatform.iOS;

  Timer? timer;
  DripSkin? sent;

  DripSkin wanted() {
    final match = ref.read(settingsProvider).matchAppIcon;
    return match ? ref.read(savedSkinProvider) : DripSkin.retroCyber;
  }

  void apply() {
    timer?.cancel();
    final skin = wanted();
    if (skin == sent) return;
    sent = skin;
    ref.read(appIconServiceProvider).setIcon(skin);
  }

  final observer = _LifecycleHook((state) {
    if (deferToBackground && state == AppLifecycleState.paused) apply();
  });
  binding.addObserver(observer);
  ref.onDispose(() {
    timer?.cancel();
    binding.removeObserver(observer);
  });

  void changed() {
    if (deferToBackground) return; // applied on the next pause
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 1500), apply);
  }

  ref.listen(savedSkinProvider, (_, _) => changed());
  ref.listen(
    settingsProvider.select((s) => s.matchAppIcon),
    (_, _) => changed(),
  );
  // First launch after an update, or after the setting drifted: converge once
  // (in the background on Android, shortly after start on iOS).
  changed();
});

class _LifecycleHook with WidgetsBindingObserver {
  _LifecycleHook(this._onState);
  final void Function(AppLifecycleState state) _onState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _onState(state);
}
