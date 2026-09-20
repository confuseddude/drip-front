import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification.dart';
import '../../data/providers.dart';

class ActivityController extends AsyncNotifier<List<ActivityItem>> {
  @override
  Future<List<ActivityItem>> build() =>
      ref.watch(activityRepositoryProvider).activity();

  Future<void> markRead(String id) async {
    state = AsyncData([
      for (final a in state.value ?? const <ActivityItem>[])
        a.id == id ? a.copyWith(isRead: true) : a,
    ]);
    await ref.read(activityRepositoryProvider).markRead(id);
  }

  Future<void> markAllRead() async {
    state = AsyncData([
      for (final a in state.value ?? const <ActivityItem>[])
        a.copyWith(isRead: true),
    ]);
    await ref.read(activityRepositoryProvider).markAllRead();
  }

  Future<void> dismiss(String id) async {
    state = AsyncData([
      for (final a in state.value ?? const <ActivityItem>[])
        if (a.id != id) a,
    ]);
    await ref.read(activityRepositoryProvider).dismiss(id);
  }
}

final activityProvider =
    AsyncNotifierProvider<ActivityController, List<ActivityItem>>(
      ActivityController.new,
    );
