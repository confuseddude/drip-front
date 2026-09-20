import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/notification.dart';
import '../../routing/main_shell.dart';
import 'activity_controller.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  static const _labels = {
    NotificationFilter.all: 'ALL',
    NotificationFilter.social: 'SOCIAL',
    NotificationFilter.dripLab: 'DRIP LAB',
  };

  void _open(ActivityItem item) {
    ref.read(activityProvider.notifier).markRead(item.id);
    switch (item.kind) {
      case NotificationKind.like:
        context.push('/ootd/ootd_moto');
      case NotificationKind.follow:
        context.push('/u/${item.actor.replaceFirst('@', '')}');
      case NotificationKind.save:
        context.push('/wardrobe');
      case NotificationKind.drip:
        context.push('/stylist');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(activityProvider);
    final accent = context.palette.accent;

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'NOTIFICATIONS',
            leading: const BackGlyph(),
            trailing: GlyphButton(
              '⚙',
              label: 'Notification settings',
              onTap: () => context.push('/settings'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  for (final f in NotificationFilter.values)
                    Expanded(
                      child: Tap(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _filter == f
                                ? accent
                                : AppColors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _labels[f]!,
                            style: AppText.mono(
                              9,
                              color: _filter == f
                                  ? AppColors.base
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: activity.whenDrip(
              onRetry: () => ref.invalidate(activityProvider),
              data: (all) {
                final items = all.where((a) => a.matches(_filter)).toList();
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'ALL CAUGHT UP',
                    message: 'No notifications here right now.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    for (final a in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Dismissible(
                          key: ValueKey(a.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              ref.read(activityProvider.notifier).dismiss(a.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'CLEAR',
                              style: AppText.mono(10, color: AppColors.red),
                            ),
                          ),
                          child: _ActivityRow(item: a, onTap: () => _open(a)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.onTap});
  final ActivityItem item;
  final VoidCallback onTap;

  (String, Color) get _badge => switch (item.kind) {
    NotificationKind.like => ('♥', AppColors.red),
    NotificationKind.follow => ('👤', AppColors.cyan),
    NotificationKind.save => ('🔖', AppColors.red),
    NotificationKind.drip => ('✦', AppColors.cyan),
  };

  @override
  Widget build(BuildContext context) {
    final (glyph, glyphColor) = _badge;
    return Tap(
      onTap: onTap,
      semanticLabel: '${item.actor} ${item.action}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isRead
                ? AppColors.cream.withValues(alpha: 0.06)
                : context.palette.accent.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.elevated, width: 1.5),
              ),
              child: ClipOval(child: DripImage(item.avatar)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.actor,
                          style: AppText.manrope(12, weight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' ${item.action}',
                          style: AppText.manrope(12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.detail,
                    style: AppText.mono(
                      10,
                      color: item.kind == NotificationKind.like
                          ? AppColors.red
                          : AppColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.timeAgo,
                    style: AppText.mono(8, color: AppColors.dim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.elevated,
                shape: BoxShape.circle,
              ),
              child: Text(glyph, style: AppText.inter(12, color: glyphColor)),
            ),
          ],
        ),
      ),
    );
  }
}
