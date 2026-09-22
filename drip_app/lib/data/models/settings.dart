import '../../core/theme/drip_skin.dart';

enum InteractAudience { everyone, mutuals, nobody }

enum OotdVisibility { public, followers, private }

extension InteractAudienceLabel on InteractAudience {
  String get label => switch (this) {
    InteractAudience.everyone => 'Everyone',
    InteractAudience.mutuals => 'Mutuals only',
    InteractAudience.nobody => 'Nobody',
  };
}

extension OotdVisibilityLabel on OotdVisibility {
  String get label => switch (this) {
    OotdVisibility.public => 'Public',
    OotdVisibility.followers => 'Followers',
    OotdVisibility.private => 'Only me',
  };
}

class UserSettings {
  const UserSettings({
    this.username = 'taylor_drip',
    this.email = 'taylor@drip.design',
    this.privateAccount = false,
    this.whoCanInteract = InteractAudience.mutuals,
    this.ootdVisibility = OotdVisibility.public,
    this.pushNotifications = true,
    this.styleMatchAlerts = true,
    this.skin = DripSkin.retroCyber,
    this.matchAppIcon = true,
  });

  final String username;
  final String email;
  final bool privateAccount;
  final InteractAudience whoCanInteract;
  final OotdVisibility ootdVisibility;
  final bool pushNotifications;
  final bool styleMatchAlerts;
  final DripSkin skin;

  /// Launcher icon follows the theme's poster (otherwise the default icon).
  final bool matchAppIcon;

  UserSettings copyWith({
    String? username,
    String? email,
    bool? privateAccount,
    InteractAudience? whoCanInteract,
    OotdVisibility? ootdVisibility,
    bool? pushNotifications,
    bool? styleMatchAlerts,
    DripSkin? skin,
    bool? matchAppIcon,
  }) => UserSettings(
    username: username ?? this.username,
    email: email ?? this.email,
    privateAccount: privateAccount ?? this.privateAccount,
    whoCanInteract: whoCanInteract ?? this.whoCanInteract,
    ootdVisibility: ootdVisibility ?? this.ootdVisibility,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    styleMatchAlerts: styleMatchAlerts ?? this.styleMatchAlerts,
    skin: skin ?? this.skin,
    matchAppIcon: matchAppIcon ?? this.matchAppIcon,
  );
}
