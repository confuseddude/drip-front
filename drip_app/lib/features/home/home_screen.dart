import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../data/models/ootd.dart';
import '../../routing/main_shell.dart';
import '../social/social_controller.dart';
import 'feed_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);
    final me = ref.watch(myProfileProvider).value;

    return ShellPage(
      child: Column(
        children: [
          _AppHeader(avatar: me?.avatar),
          const _StoriesStrip(),
          Expanded(
            child: feed.whenDrip(
              onRetry: () => ref.invalidate(feedProvider),
              data: (posts) => posts.isEmpty
                  ? const EmptyState(
                      title: 'NOTHING YET',
                      message: 'Follow more creators to fill your feed.',
                    )
                  : _FeedPager(posts: posts),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({this.avatar});
  final String? avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: AppColors.elevated)),
      ),
      child: Row(
        children: [
          Text('DRIP', style: AppText.bungee(22)),
          const Spacer(),
          Tap(
            onTap: () => context.push('/stylist'),
            semanticLabel: 'Taylor stylist',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '✦ TAYLOR',
                style: AppText.mono(
                  10,
                  color: AppColors.base,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tap(
            onTap: () => context.go('/me'),
            semanticLabel: 'Your profile',
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cream),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatar == null
                    ? const ColoredBox(color: AppColors.elevated)
                    : DripImage(avatar!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoriesStrip extends ConsumerWidget {
  const _StoriesStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR OOTD · FOLLOWED',
            style: AppText.mono(10, color: AppColors.muted, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 68,
            child: stories.when(
              data: (list) => ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _StoryBubble(
                  story: list[i],
                  onTap: () {
                    final id = list[i].ootdId;
                    if (id == null) return;
                    ref.read(storiesProvider.notifier).markSeen(list[i].handle);
                    context.push('/ootd/$id');
                  },
                ),
              ),
              loading: () => const LoadingState(compact: true),
              error: (_, _) => Align(
                alignment: Alignment.centerLeft,
                child: Tap(
                  onTap: () => ref.invalidate(storiesProvider),
                  child: Text(
                    'COULDN\'T LOAD · TAP TO RETRY',
                    style: AppText.mono(9, color: AppColors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story, required this.onTap});
  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = story.unseen ? AppColors.red : AppColors.elevated;
    return Tap(
      onTap: onTap,
      semanticLabel: '${story.handle} story',
      child: SizedBox(
        width: 52,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: ring, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: story.unseen
                        ? const Color(0x40FF2020)
                        : const Color(0x33000000),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(child: DripImage(story.avatar)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '@${story.handle}',
                maxLines: 1,
                softWrap: false,
                style: AppText.manrope(9, lineHeight: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical pager of outfit cards: swipe up for the next fit.
class _FeedPager extends ConsumerStatefulWidget {
  const _FeedPager({required this.posts});
  final List<Ootd> posts;

  @override
  ConsumerState<_FeedPager> createState() => _FeedPagerState();
}

class _FeedPagerState extends ConsumerState<_FeedPager> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    final current = posts[_page.clamp(0, posts.length - 1)];
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            itemCount: posts.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.all(16),
              child: OotdCard(post: posts[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Tap(
                onTap: () {
                  if (_page < posts.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    showDripToast(context, "You're all caught up");
                  }
                },
                child: Text(
                  '↑ SWIPE UP NEXT FIT',
                  style: AppText.mono(9, color: AppColors.muted),
                ),
              ),
              Row(
                children: [
                  Tap(
                    onTap: () => context.push(
                      '/outfit/${current.outfitId ?? 'o_cyber_flare'}',
                    ),
                    child: Text(
                      '→ SHOP OUTFIT',
                      style: AppText.mono(9, color: AppColors.cyan),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tap(
                    onTap: () => context.push('/studio'),
                    child: Text(
                      '→→ CUSTOMIZE',
                      style: AppText.mono(9, color: AppColors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single feed card. Tap opens the viewer, double-tap saves, swipe right
/// opens the outfit breakdown.
class OotdCard extends ConsumerStatefulWidget {
  const OotdCard({super.key, required this.post});
  final Ootd post;

  @override
  ConsumerState<OotdCard> createState() => _OotdCardState();
}

class _OotdCardState extends ConsumerState<OotdCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _saveWithBurst() {
    final feed = ref.read(feedProvider.notifier);
    if (!widget.post.isSaved) feed.toggleSave(widget.post.id);
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final accent = context.palette.accent;
    return GestureDetector(
      onTap: () => context.push('/ootd/${post.id}'),
      onDoubleTap: _saveWithBurst,
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 400) {
          context.push('/outfit/${post.outfitId ?? 'o_cyber_flare'}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DripImage(post.image),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC0E1018), Color(0x000E1018)],
                    stops: [0, 0.6],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.base,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cyan),
                          ),
                          child: Text(
                            'ERA: ${post.era}',
                            style: AppText.mono(10, color: AppColors.cyan),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'DRIP SCORE: ${post.score}',
                            style: AppText.bungee(10, color: AppColors.base),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _Meta(post: post)),
                        _Sidebar(post: post),
                      ],
                    ),
                  ],
                ),
              ),
              Center(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _burst,
                    builder: (context, _) {
                      final t = _burst.value;
                      final scale =
                          0.6 +
                          Curves.elasticOut.transform(t.clamp(0, 1)) * 0.8;
                      final opacity = t == 0
                          ? 0.0
                          : (t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4)).clamp(
                              0.0,
                              1.0,
                            );
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Text('🔖', style: AppText.inter(72)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.post});
  final Ootd post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Tap(
          onTap: () => context.push('/u/${post.creatorHandle}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: ClipOval(child: DripImage(post.creatorAvatar)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${post.creatorHandle}',
                    style: AppText.manrope(13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'EST. 2077',
                    style: AppText.mono(9, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.manrope(14, weight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [for (final t in post.tags) TagChip(t.toUpperCase())],
        ),
      ],
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.post});
  final Ootd post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.read(feedProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Action(
          glyph: post.isLiked ? '♥' : '♡',
          color: post.isLiked ? AppColors.red : AppColors.cream,
          label: formatCount(post.likes),
          onTap: () => feed.toggleLike(post.id),
          semantic: post.isLiked ? 'Unlike' : 'Like',
        ),
        const SizedBox(height: 14),
        _Action(
          glyph: '🔖',
          color: AppColors.cream,
          active: post.isSaved,
          label: formatCount(post.saves),
          onTap: () {
            feed.toggleSave(post.id);
            showDripToast(
              context,
              post.isSaved ? 'Removed from saved' : 'Saved to your vault',
            );
          },
          semantic: post.isSaved ? 'Unsave' : 'Save',
        ),
        const SizedBox(height: 14),
        _Action(
          glyph: '↗',
          color: AppColors.cream,
          size: 16,
          onTap: () =>
              context.push('/outfit/${post.outfitId ?? 'o_cyber_flare'}'),
          semantic: 'Open outfit',
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.glyph,
    required this.color,
    required this.onTap,
    required this.semantic,
    this.label,
    this.size = 18,
    this.active = false,
  });

  final String glyph;
  final Color color;
  final String? label;
  final double size;
  final bool active;
  final VoidCallback onTap;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: semantic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: active ? Border.all(color: context.palette.accent) : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(glyph, style: AppText.inter(size, color: color)),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(label!, style: AppText.mono(9)),
          ],
        ],
      ),
    );
  }
}
