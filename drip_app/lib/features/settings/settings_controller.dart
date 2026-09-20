import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/drip_skin.dart';
import '../../data/models/settings.dart';
import '../../data/providers.dart';

/// User-editable settings, persisted on this device.
class SettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() => ref.watch(localStoreProvider).loadSettings();

  Future<void> _update(UserSettings next) async {
    state = next;
    await ref.read(localStoreProvider).saveSettings(next);
  }

  Future<void> setUsername(String v) => _update(state.copyWith(username: v));
  Future<void> setEmail(String v) => _update(state.copyWith(email: v));
  Future<void> setPrivate(bool v) => _update(state.copyWith(privateAccount: v));
  Future<void> setWhoCanInteract(InteractAudience v) =>
      _update(state.copyWith(whoCanInteract: v));
  Future<void> setOotdVisibility(OotdVisibility v) =>
      _update(state.copyWith(ootdVisibility: v));
  Future<void> setPush(bool v) => _update(state.copyWith(pushNotifications: v));
  Future<void> setStyleAlerts(bool v) =>
      _update(state.copyWith(styleMatchAlerts: v));
  Future<void> setSkin(DripSkin v) => _update(state.copyWith(skin: v));
}

final settingsProvider = NotifierProvider<SettingsController, UserSettings>(
  SettingsController.new,
);

/// Third-party accounts linked to Drip (UI state until the integrations exist).
class ConnectedAccountsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'Discord', 'Spotify'};

  void toggle(String name) => state = state.contains(name)
      ? ({...state}..remove(name))
      : {...state, name};
}

final connectedAccountsProvider =
    NotifierProvider<ConnectedAccountsController, Set<String>>(
      ConnectedAccountsController.new,
    );

/// The active skin, watched by the app root to rebuild the theme.
final skinProvider = Provider<DripSkin>(
  (ref) => ref.watch(settingsProvider.select((s) => s.skin)),
);
