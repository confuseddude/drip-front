import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/user.dart';
import '../../routing/main_shell.dart';
import '../social/social_controller.dart';
import 'profile_controller.dart';
import 'profile_widgets.dart';

/// `/u/:handle` — another creator's portfolio. Private accounts show the
/// locked "secure access" view until access is granted.
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.handle});
  final String handle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider(handle));
    return user.when(
      data: (u) {
        if (u == null) {
          return ShellPage(
            child: Column(
              children: [
                const DripTopBar(
                  title: 'PUBLIC PORTFOLIO',
                  leading: BackGlyph(mono: true),
                ),
                Expanded(
                  child: EmptyState(
                    title: 'CREATOR NOT FOUND',
                    message: '@$handle isn\'t on Drip yet.',
                  ),
                ),
              ],
            ),
          );
        }
        if (isMe(u.handle)) return _redirectToMe(context);
        return u.isPrivate ? _PrivateView(user: u) : _PublicView(user: u);
      },
      loading: () => const ShellPage(child: LoadingState()),
      error: (_, _) => ShellPage(
        child: ErrorState(onRetry: () => ref.invalidate(userProvider(handle))),
      ),
    );
  }

  Widget _redirectToMe(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go('/me');
    });
    return const ShellPage(child: LoadingState(compact: true));
  }
}

class _PublicView extends ConsumerStatefulWidget {
  const _PublicView({required this.user});
  final DripUser user;

  @override
  ConsumerState<_PublicView> createState() => _PublicViewState();
}

class _PublicViewState extends ConsumerState<_PublicView> {
  int _tab = 0;

  Future<void> _message() async {
    final c = TextEditingController();
    final sent = await showDripSheet<bool>(
      context,
      builder: (ctx) => SheetContent(
        title: 'MESSAGE ${widget.user.at.toUpperCase()}',
        children: [
          DripField(
            controller: c,
            hint: 'Say something...',
            radius: 14,
            autofocus: true,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'SEND',
            height: 44,
            radius: 14,
            onPressed: () => Navigator.of(ctx).pop(c.text.trim().isNotEmpty),
          ),
        ],
      ),
    );
    c.dispose();
    if (sent == true && mounted) {
      showDripToast(context, 'Message sent to ${widget.user.at}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final following =
        ref.watch(followingSetProvider).value?.contains(user.handle) ?? false;
    final fits = ref.watch(profileFitsProvider(user.handle));
    final posts = ref.watch(profilePostsProvider(user.handle));
    final accent = context.palette.accent;

    final tiles = _tab == 0
        ? [for (final o in fits) PhotoTile(o.image, '/outfit/${o.id}')]
        : [for (final p in posts) PhotoTile(p.image, '/ootd/${p.id}')];

    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'PUBLIC PORTFOLIO',
            card: true,
            height: 44,
            leading: const BackGlyph(mono: true),
            trailing: GlyphButton(
              '💬',
              mono: true,
              label: 'Message',
              onTap: _message,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      ProfileIntro(
                        user: user,
                        ringColor: accent,
                        nameSize: 18,
                        trailing: Tap(
                          onTap: () async {
                            await ref
                                .read(followingSetProvider.notifier)
                                .toggle(user.handle);
                            if (context.mounted) {
                              showDripToast(
                                context,
                                following
                                    ? 'Unfollowed ${user.at}'
                                    : 'Following ${user.at}',
                              );
                            }
                          },
                          semanticLabel: following ? 'Unfollow' : 'Follow',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: following ? AppColors.transparent : accent,
                              borderRadius: BorderRadius.circular(12),
                              border: following
                                  ? Border.all(color: AppColors.muted)
                                  : null,
                              boxShadow: following
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.2),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Text(
                              following ? 'FOLLOWING' : 'FOLLOW',
                              style: AppText.mono(
                                9,
                                color: following
                                    ? AppColors.muted
                                    : AppColors.base,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ProfileStats(user: user, radius: 20),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SectionLabel(
                          "${user.name.split(' ').first.toUpperCase()}'S STYLE DNA",
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DnaChips(tags: user.styleDna, radius: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      ProfileTabs(
                        labels: const ['FITS', 'OOTD ARCHIVE'],
                        index: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                        size: 14,
                      ),
                      if (tiles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: EmptyState(
                            title: _tab == 0 ? 'NO FITS YET' : 'NO OOTDS YET',
                            message: '${user.at} hasn\'t posted here yet.',
                          ),
                        )
                      else
                        PhotoGrid(tiles: tiles, height: 150, radius: 20),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    '${formatCount(user.followers)} FOLLOWERS · STYLE SCORE ${user.styleScore}',
                    textAlign: TextAlign.center,
                    style: AppText.mono(9, color: AppColors.dim),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateView extends ConsumerWidget {
  const _PrivateView({required this.user});
  final DripUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requested = ref.watch(accessRequestsProvider).contains(user.handle);
    return ShellPage(
      child: Column(
        children: [
          DripTopBar(
            title: 'SECURE ACCESS',
            card: true,
            height: 44,
            cardColor: AppColors.deep,
            leading: const BackGlyph(mono: true),
            trailing: GlyphButton(
              '🔒',
              mono: true,
              label: 'Private',
              onTap: () => showDripToast(context, 'This account is private'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.elevated, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: DripImage(user.avatar),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AppText.display(18)),
                        const SizedBox(height: 4),
                        Text(
                          user.at,
                          style: AppText.mono(11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ESTD 2077',
                          style: AppText.mono(10, color: AppColors.cyan),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.elevated),
                  ),
                  child: Column(
                    children: [
                      Text('🔒', style: AppText.mono(32)),
                      const SizedBox(height: 12),
                      Text(
                        'PRIVATE ACCOUNT',
                        textAlign: TextAlign.center,
                        style: AppText.display(14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Follow to see their fits, color theory analysis, and daily lookbooks.',
                        textAlign: TextAlign.center,
                        style: AppText.manrope(
                          12,
                          color: AppColors.muted,
                          lineHeight: 17,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: requested ? 'REQUESTED ✓' : 'REQUEST ACCESS ✦',
                        height: 40,
                        radius: 16,
                        style: requested
                            ? AppButtonStyle.outline
                            : AppButtonStyle.primary,
                        textStyle: AppText.display(12),
                        onPressed: () {
                          ref
                              .read(accessRequestsProvider.notifier)
                              .toggle(user.handle);
                          showDripToast(
                            context,
                            requested
                                ? 'Request withdrawn'
                                : 'Access requested',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.elevated),
                  ),
                  child: Column(
                    children: [
                      for (final label in const [
                        'STYLE SCORE',
                        'DNA SPECTRUM',
                      ]) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: AppText.mono(10, color: AppColors.muted),
                            ),
                            Text('[RESTRICTED]', style: AppText.mono(10)),
                          ],
                        ),
                        if (label == 'STYLE SCORE') const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
