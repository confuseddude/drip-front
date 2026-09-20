import '../mock/mock_content.dart';
import '../models/notification.dart';

abstract interface class ActivityRepository {
  Future<List<ActivityItem>> activity();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> dismiss(String id);
}

class MockActivityRepository implements ActivityRepository {
  final List<ActivityItem> _items = List.of(MockContent.activity);

  @override
  Future<List<ActivityItem>> activity() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) _items[i] = _items[i].copyWith(isRead: true);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> dismiss(String id) async =>
      _items.removeWhere((e) => e.id == id);
}
