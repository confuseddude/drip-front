import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/drip_skin.dart';
import '../models/settings.dart';

/// Thin typed wrapper over [SharedPreferences]. This is *device-local*
/// persistence (session flag, onboarding picks, settings, recent searches,
/// follow list) — not a substitute for the future backend.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _signedIn = 'session.signedIn';
  static const _onboarded = 'session.onboarded';
  static const _moods = 'onboarding.moods';
  static const _palette = 'onboarding.palette';
  static const _following = 'social.following';
  static const _recents = 'search.recents';

  bool get signedIn => _prefs.getBool(_signedIn) ?? false;
  bool get onboarded => _prefs.getBool(_onboarded) ?? false;

  Future<void> setSignedIn(bool v) => _prefs.setBool(_signedIn, v);
  Future<void> setOnboarded(bool v) => _prefs.setBool(_onboarded, v);

  Set<String>? get moodIds => _prefs.getStringList(_moods)?.toSet();
  Future<void> setMoodIds(Set<String> ids) =>
      _prefs.setStringList(_moods, ids.toList());

  Set<String>? get paletteIds => _prefs.getStringList(_palette)?.toSet();
  Future<void> setPaletteIds(Set<String> ids) =>
      _prefs.setStringList(_palette, ids.toList());

  Set<String>? get following => _prefs.getStringList(_following)?.toSet();
  Future<void> setFollowing(Set<String> handles) =>
      _prefs.setStringList(_following, handles.toList());

  List<String>? get recentSearches => _prefs.getStringList(_recents);
  Future<void> setRecentSearches(List<String> v) =>
      _prefs.setStringList(_recents, v);

  UserSettings loadSettings() {
    const d = UserSettings();
    return UserSettings(
      username: _prefs.getString('settings.username') ?? d.username,
      email: _prefs.getString('settings.email') ?? d.email,
      privateAccount: _prefs.getBool('settings.private') ?? d.privateAccount,
      whoCanInteract:
          InteractAudience.values.asNameMap()[_prefs.getString(
            'settings.interact',
          )] ??
          d.whoCanInteract,
      ootdVisibility:
          OotdVisibility.values.asNameMap()[_prefs.getString(
            'settings.visibility',
          )] ??
          d.ootdVisibility,
      pushNotifications: _prefs.getBool('settings.push') ?? d.pushNotifications,
      styleMatchAlerts:
          _prefs.getBool('settings.styleAlerts') ?? d.styleMatchAlerts,
      skin: DripSkin.fromId(_prefs.getString('settings.skin')),
    );
  }

  Future<void> saveSettings(UserSettings s) async {
    await _prefs.setString('settings.username', s.username);
    await _prefs.setString('settings.email', s.email);
    await _prefs.setBool('settings.private', s.privateAccount);
    await _prefs.setString('settings.interact', s.whoCanInteract.name);
    await _prefs.setString('settings.visibility', s.ootdVisibility.name);
    await _prefs.setBool('settings.push', s.pushNotifications);
    await _prefs.setBool('settings.styleAlerts', s.styleMatchAlerts);
    await _prefs.setString('settings.skin', s.skin.id);
  }

  /// Wipes everything tied to the signed-in account (logout).
  Future<void> clearAccount() async {
    for (final k in _prefs.getKeys().toList()) {
      await _prefs.remove(k);
    }
  }
}
