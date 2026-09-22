import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/user.dart';
import '../../routing/main_shell.dart';
import 'social_controller.dart';

/// One row in the followers / following lists.
class UserRow extends StatelessWidget {
  const UserRow({
    super.key,
    required this.user,
    required this.actionLabel,
    required this.actionStyle,
    required this.onAction,
    required this.footnote,
  });

  final DripUser user;
  final String actionLabel;
  final UserRowAction actionStyle;
  final VoidCallback onAction;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final (fill, textColor, border) = switch (actionStyle) {
      UserRowAction.mutual => (AppColors.elevated, AppColors.muted, null),
      UserRowAction.follow => (accent, AppColors.base, null),
      UserRowAction.unfollow => (
        AppColors.elevated,
        AppColors.red,
        AppColors.red.withValues(alpha: 0.06),
      ),
    };
    return Tap(
      onTap: () => context.push('/u/${user.handle}'),
      semanticLabel: user.name,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.elevated),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.elevated, width: 1.5),
              ),
              child: ClipOval(child: DripImage(user.avatar)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(11),
                  ),
                  const SizedBox(height: 2),
                  Text(user.at, style: AppText.mono(9, color: AppColors.cyan)),
                  const SizedBox(height: 2),
                  Text(
                    user.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mono(8, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Tap(
                  onTap: onAction,
                  semanticLabel: actionLabel,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(8),
                      border: border == null ? null : Border.all(color: border),
                    ),
                    child: Text(
                      actionLabel,
                      style: AppText.mono(8, color: textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(footnote, style: AppText.mono(7, color: AppColors.dim)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum UserRowAction { mutual, follow, unfollow }

/// Search field used above both lists.
class ListSearchField extends StatelessWidget {
  const ListSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DripField(
      hint: hint,
      hintColor: AppColors.dim,
      radius: 16,
      borderColor: AppColors.cream.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Text('🔍', style: AppText.inter(14, color: AppColors.muted)),
      onChanged: onChanged,
    );
  }
}

class FollowersScreen extends ConsumerStatefulWidget {
  const FollowersScreen({super.key});

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(followersPageProvider);
    final following = ref.watch(followingSetProvider).value ?? const <String>{};

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'FOLLOWERS',
            leading: const BackGlyph(),
            trailing: GlyphButton(
              '🔍',
              label: 'Search',
              onTap: () => showDripToast(context, 'Type in the search field'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ListSearchField(
              hint: 'Search followers...',
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: page.whenDrip(
              onRetry: () => ref.invalidate(followersPageProvider),
              data: (p) {
                final users = p.users
                    .where(
                      (u) =>
                          _q.isEmpty ||
                          '${u.name} ${u.handle}'.toLowerCase().contains(_q),
                    )
                    .toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _q.isEmpty
                            ? '${formatThousands(p.total)} CREATIVE FOLLOWERS'
                            : '${users.length} MATCHES',
                        style: AppText.mono(
                          10,
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (users.isEmpty)
                      const EmptyState(
                        title: 'NO MATCHES',
                        message: 'No followers match that search.',
                      )
                    else
                      for (final u in users) ...[
                        UserRow(
                          user: u,
                          actionLabel: following.contains(u.handle)
                              ? 'MUTUAL'
                              : 'FOLLOW',
                          actionStyle: following.contains(u.handle)
                              ? UserRowAction.mutual
                              : UserRowAction.follow,
                          footnote: 'Style ${u.styleScore}',
                          onAction: () => ref
                              .read(followingSetProvider.notifier)
                              .toggle(u.handle),
                        ),
                        const SizedBox(height: 8),
                      ],
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

class FollowingScreen extends ConsumerStatefulWidget {
  const FollowingScreen({super.key});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  String _q = '';
  int _filter = 0; // 0 all · 1 brands · 2 creators

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(followingPageProvider);
    final following = ref.watch(followingSetProvider).value ?? const <String>{};

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'FOLLOWING',
            leading: const BackGlyph(mono: true),
            trailing: GlyphButton(
              '🎨',
              mono: true,
              label: 'Colour theory',
              onTap: () => context.push('/me/colour-theory'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ListSearchField(
              hint: 'Search curators & designers...',
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                children: [
                  for (final (i, label) in [
                    'ALL (${page.value?.total ?? 0})',
                    'BRANDS',
                    'CREATORS',
                  ].indexed)
                    FilterPill(
                      label: label,
                      selected: _filter == i,
                      selectedColor: AppColors.cyan,
                      radius: 8,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: AppText.mono(
                        8,
                        color: _filter == i ? AppColors.base : AppColors.muted,
                      ),
                      onTap: () => setState(() => _filter = i),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: page.whenDrip(
              onRetry: () => ref.invalidate(followingPageProvider),
              data: (p) {
                final users = p.users.where((u) {
                  final isBrand = u.badge == 'Off. Brand';
                  final matchesFilter =
                      _filter == 0 || (_filter == 1 ? isBrand : !isBrand);
                  final matchesQuery =
                      _q.isEmpty ||
                      '${u.name} ${u.handle}'.toLowerCase().contains(_q);
                  return matchesFilter && matchesQuery;
                }).toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _q.isEmpty && _filter == 0
                            ? '${p.total} STYLISTS IN YOUR SPHERE'
                            : '${users.length} MATCHES',
                        style: AppText.mono(
                          10,
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (users.isEmpty)
                      const EmptyState(
                        title: 'NO MATCHES',
                        message: 'Nobody in your sphere matches that.',
                      )
                    else
                      for (final u in users) ...[
                        UserRow(
                          user: u,
                          actionLabel: following.contains(u.handle)
                              ? 'UNFOLLOW'
                              : 'FOLLOW',
                          actionStyle: following.contains(u.handle)
                              ? UserRowAction.unfollow
                              : UserRowAction.follow,
                          footnote: u.badge.isEmpty
                              ? 'Style ${u.styleScore}'
                              : u.badge,
                          onAction: () async {
                            final was = following.contains(u.handle);
                            if (was) {
                              final ok = await showDripConfirm(
                                context,
                                title: 'UNFOLLOW ${u.name.toUpperCase()}?',
                                message: 'Their fits will leave your feed.',
                                confirmLabel: 'UNFOLLOW',
                                destructive: true,
                              );
                              if (!ok) return;
                            }
                            await ref
                                .read(followingSetProvider.notifier)
                                .toggle(u.handle);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
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
