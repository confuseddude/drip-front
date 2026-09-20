import 'package:flutter/painting.dart';

/// A Drip creator / account. Used for the signed-in user, profile screens and
/// the followers / following lists.
class DripUser {
  const DripUser({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatar,
    this.bio = '',
    this.tagline = '',
    this.badge = '',
    this.followers = 0,
    this.following = 0,
    this.styleScore = 0,
    this.styleDna = const [],
    this.palette = const [],
    this.isPrivate = false,
    this.location = '',
  });

  final String id;
  final String name;

  /// Handle without the leading `@`.
  final String handle;
  final String avatar;
  final String bio;

  /// Short descriptor shown on list rows, e.g. `NEO GRUNGE · MOTO`.
  final String tagline;

  /// Relationship / role tag, e.g. `Curator`, `Off. Brand`.
  final String badge;
  final int followers;
  final int following;
  final int styleScore;
  final List<String> styleDna;
  final List<Color> palette;
  final bool isPrivate;
  final String location;

  String get at => '@$handle';

  DripUser copyWith({
    String? name,
    String? handle,
    String? bio,
    String? avatar,
  }) => DripUser(
    id: id,
    name: name ?? this.name,
    handle: handle ?? this.handle,
    avatar: avatar ?? this.avatar,
    bio: bio ?? this.bio,
    tagline: tagline,
    badge: badge,
    followers: followers,
    following: following,
    styleScore: styleScore,
    styleDna: styleDna,
    palette: palette,
    isPrivate: isPrivate,
    location: location,
  );
}
