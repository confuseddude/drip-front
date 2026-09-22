/// A post in the home feed / OOTD viewer.
class Ootd {
  const Ootd({
    required this.id,
    required this.creatorHandle,
    required this.creatorAvatar,
    required this.image,
    required this.title,
    required this.era,
    required this.score,
    required this.likes,
    required this.saves,
    required this.tags,
    required this.postedAgo,
    this.outfitId,
    this.caption = '',
    this.location = '',
    this.comments = 0,
    this.shares = 0,
    this.views = 0,
    this.isLiked = false,
    this.isSaved = false,
  });

  final String id;
  final String creatorHandle;
  final String creatorAvatar;
  final String image;
  final String title;
  final String era;
  final int score;
  final int likes;
  final int saves;
  final List<String> tags;
  final String postedAgo;
  final String? outfitId;
  final String caption;
  final String location;
  final int comments;
  final int shares;
  final int views;
  final bool isLiked;
  final bool isSaved;

  Ootd copyWith({
    bool? isLiked,
    bool? isSaved,
    int? likes,
    int? saves,
    int? comments,
    int? shares,
  }) => Ootd(
    id: id,
    creatorHandle: creatorHandle,
    creatorAvatar: creatorAvatar,
    image: image,
    title: title,
    era: era,
    score: score,
    likes: likes ?? this.likes,
    saves: saves ?? this.saves,
    tags: tags,
    postedAgo: postedAgo,
    outfitId: outfitId,
    caption: caption,
    location: location,
    comments: comments ?? this.comments,
    shares: shares ?? this.shares,
    views: views,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
  );
}

/// A creator shown in the stories strip at the top of the home feed.
class Story {
  const Story({
    required this.handle,
    required this.avatar,
    this.unseen = false,
    this.ootdId,
  });
  final String handle;
  final String avatar;
  final bool unseen;

  /// The OOTD opened when the story is tapped.
  final String? ootdId;

  Story copyWith({bool? unseen}) => Story(
    handle: handle,
    avatar: avatar,
    unseen: unseen ?? this.unseen,
    ootdId: ootdId,
  );
}

/// A comment on an OOTD (Fashion Scroll comments sheet).
class OotdComment {
  const OotdComment({
    required this.id,
    required this.handle,
    required this.avatar,
    required this.text,
    required this.ago,
    this.likes = 0,
  });

  final String id;
  final String handle;
  final String avatar;
  final String text;
  final String ago;
  final int likes;
}
