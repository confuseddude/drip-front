enum NotificationKind { like, follow, save, drip }

enum NotificationFilter { all, social, dripLab }

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.actor,
    required this.avatar,
    required this.action,
    required this.detail,
    required this.timeAgo,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String actor;
  final String avatar;
  final String action;
  final String detail;
  final String timeAgo;
  final bool isRead;

  bool matches(NotificationFilter filter) => switch (filter) {
    NotificationFilter.all => true,
    NotificationFilter.social => kind != NotificationKind.drip,
    NotificationFilter.dripLab => kind == NotificationKind.drip,
  };

  ActivityItem copyWith({bool? isRead}) => ActivityItem(
    id: id,
    kind: kind,
    actor: actor,
    avatar: avatar,
    action: action,
    detail: detail,
    timeAgo: timeAgo,
    isRead: isRead ?? this.isRead,
  );
}
