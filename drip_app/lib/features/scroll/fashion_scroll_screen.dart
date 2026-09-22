import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/fit_hero.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/like_burst.dart';
import '../../core/widgets/nav_glyphs.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../data/mock/mock_users.dart';
import '../../data/models/ootd.dart';
import '../../data/models/outfit.dart';
import '../home/feed_controller.dart';
import '../outfits/outfit_controller.dart';
import '../social/social_controller.dart';
import 'scroll_sheets.dart';

/// The Fashion Scroll: full-screen, one fit at a time, snapping vertically —
/// and infinite, exactly like Instagram Reels: once you reach the last fit it
/// loops seamlessly back to the first, forever, in both scroll directions.
///
/// Only the visible page is built (`PageView.builder`), the next image is
/// pre-cached, and everything laid over the photo is either a gradient or a
/// small glass element, so the photograph stays the hero.
class FashionScrollScreen extends ConsumerStatefulWidget {
  const FashionScrollScreen({super.key, this.startId});

  /// Fit to open on (from Home). Null starts at the top of the feed.
  final String? startId;

  @override
  ConsumerState<FashionScrollScreen> createState() =>
      _FashionScrollScreenState();
}

class _FashionScrollScreenState extends ConsumerState<FashionScrollScreen> {
  /// Large offset so the loop can also scroll "backward" past the first
  /// post for a long time before it would ever hit page 0.
  static const _loopOffset = 100000;

  PageController? _pc;
  int _page = 0;

  @override
  void dispose() {
    _pc?.dispose();
    super.dispose();
  }

  PageController _controllerFor(List<Ootd> posts) {
    if (_pc != null) return _pc!;
    final start = widget.startId == null
        ? 0
        : posts
              .indexWhere((p) => p.id == widget.startId)
              .clamp(0, posts.length);
    _page = _loopOffset * posts.length + start;
    return _pc = PageController(initialPage: _page);
  }

  void _precache(List<Ootd> posts, int i) {
    for (final j in [i + 1, i + 2]) {
      precacheImage(dripImageProvider(posts[j % posts.length].image), context);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        // Reached via the tab (no Home underneath): back goes Home, not out.
        if (!didPop) context.go('/home');
      },
      child: feed.when(
        loading: () => const _ReelSkeleton(),
        error: (_, _) =>
            ErrorState(onRetry: () => ref.invalidate(feedProvider)),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyState(
              title: 'NOTHING TO SCROLL',
              message: 'Follow creators to fill your Fashion Scroll.',
            );
          }
          final pc = _controllerFor(posts);
          _precache(posts, _page);
          return Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: pc,
                scrollDirection: Axis.vertical,
                // A touch of resistance at the ends, native-feeling physics.
                physics: const PageScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                // No itemCount: unbounded in both directions, so the reel
                // never runs out — it just keeps wrapping through `posts`.
                onPageChanged: (i) {
                  setState(() => _page = i);
                  _precache(posts, i);
                },
                itemBuilder: (context, i) => _ReelPage(
                  post: posts[i % posts.length],
                  active: i == _page,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopChrome(
                  index: _page % posts.length,
                  count: posts.length,
                  onBack: context.canPop() ? _back : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────── chrome

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.index,
    required this.count,
    required this.onBack,
  });

  final int index;
  final int count;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 16, 0),
        child: Row(
          children: [
            if (onBack != null)
              GlassIconButton(
                semanticLabel: 'Back',
                onTap: onBack,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: AppColors.cream,
                ),
              )
            else
              const SizedBox(width: 8),
            Glass(
              radius: 20,
              thickness: GlassThickness.thin,
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ReelGlyph(color: AppColors.cream, size: 18, glow: 1),
                  const SizedBox(width: 8),
                  Text(
                    'FASHION SCROLL',
                    style: AppText.mono(
                      10,
                      weight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Glass(
              radius: 16,
              thickness: GlassThickness.thin,
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                '${index + 1} / $count',
                style: AppText.mono(10, color: AppColors.cream),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── page

class _ReelPage extends ConsumerStatefulWidget {
  const _ReelPage({required this.post, required this.active});
  final Ootd post;
  final bool active;

  @override
  ConsumerState<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<_ReelPage> {
  int _burst = 0;

  void _doubleTapLike() {
    final post = widget.post;
    if (!post.isLiked) {
      ref.read(feedProvider.notifier).toggleLike(post.id);
    }
    Haptics.thump();
    setState(() => _burst++);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    // Includes the floating nav's height (the shell adds it).
    final bottom = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
      onDoubleTap: _doubleTapLike,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FitHero(
            ootdId: post.id,
            radius: 28,
            child: SizedBox.expand(
              child: DripImage(post.image, alignment: Alignment.topCenter),
            ),
          ),
          // Top scrim keeps the chrome legible on bright photos.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          // Bottom scrim carries the description.
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 420,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF00E1018), Color(0x000E1018)],
                    stops: [0.1, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 84,
            bottom: bottom + 6,
            child: _Description(post: post),
          ),
          Positioned(
            right: 8,
            bottom: bottom + 10,
            child: _ActionRail(post: post),
          ),
          Center(child: LikeBurst(trigger: _burst, size: 110)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── description

/// Creator, caption, style and shop details, written like part of the post
/// rather than an analytics panel: stats sit in one quiet line.
class _Description extends ConsumerStatefulWidget {
  const _Description({required this.post});
  final Ootd post;

  @override
  ConsumerState<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends ConsumerState<_Description> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final p = context.palette;
    final outfit = post.outfitId == null
        ? null
        : ref.watch(outfitProvider(post.outfitId!));
    final following = ref.watch(followingSetProvider).value ?? const {};
    final isMe = post.creatorHandle == MockUsers.meHandle;
    final isFollowing = following.contains(post.creatorHandle);
    final caption = post.caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Creator
        Row(
          children: [
            Flexible(
              child: Tap(
                onTap: () => context.push('/u/${post.creatorHandle}'),
                semanticLabel: 'Open @${post.creatorHandle} profile',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.accent, width: 1.5),
                      ),
                      child: ClipOval(child: DripImage(post.creatorAvatar)),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${post.creatorHandle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.manrope(14, weight: FontWeight.w800),
                          ),
                          Text(
                            post.postedAgo,
                            style: AppText.mono(9, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!isMe) ...[
              const SizedBox(width: 12),
              _FollowChip(
                following: isFollowing,
                onTap: () {
                  Haptics.commit();
                  ref
                      .read(followingSetProvider.notifier)
                      .toggle(post.creatorHandle);
                  showDripToast(
                    context,
                    isFollowing
                        ? 'Unfollowed @${post.creatorHandle}'
                        : 'Following @${post.creatorHandle}',
                  );
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          post.title.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.display(18, lineHeight: 22),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Tap(
            onTap: () => setState(() => _expanded = !_expanded),
            semanticLabel: _expanded ? 'Collapse caption' : 'Expand caption',
            child: AnimatedSize(
              duration: Motion.quick,
              curve: Motion.out,
              alignment: Alignment.topLeft,
              child: Text(
                caption,
                maxLines: _expanded ? 8 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.manrope(
                  13,
                  lineHeight: 18,
                  color: AppColors.cream.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MetaChip('ERA · ${post.era}', filled: true),
            for (final t in post.tags.take(3)) _MetaChip(t.toUpperCase()),
          ],
        ),
        const SizedBox(height: 10),
        if (outfit != null) _ShopStrip(outfit: outfit),
        const SizedBox(height: 10),
        // Stats: one quiet line, integrated with the post.
        Row(
          children: [
            const Icon(
              Icons.visibility_rounded,
              size: 13,
              color: AppColors.muted,
            ),
            const SizedBox(width: 5),
            Text(
              '${formatCount(post.views)} views',
              style: AppText.mono(10, color: AppColors.muted),
            ),
            const SizedBox(width: 10),
            Text('·', style: AppText.mono(10, color: AppColors.dim)),
            const SizedBox(width: 10),
            Text(
              '✦ DRIP ${post.score}',
              style: AppText.mono(10, color: p.accent, weight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _FollowChip extends StatelessWidget {
  const _FollowChip({required this.following, required this.onTap});
  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Tap(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: following ? 'Following, tap to unfollow' : 'Follow',
      child: AnimatedContainer(
        duration: Motion.quick,
        curve: Motion.out,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: following ? Colors.white.withValues(alpha: 0.10) : accent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: following ? Colors.white.withValues(alpha: 0.28) : accent,
          ),
        ),
        child: Text(
          following ? 'FOLLOWING' : 'FOLLOW',
          style: AppText.mono(
            10,
            color: following ? AppColors.cream : AppColors.base,
            weight: FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label, {this.filled = false});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: AppText.mono(
          9,
          weight: filled ? FontWeight.w500 : FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Brand, piece count and price range of the outfit, from the real outfit
/// data. Tapping opens the full breakdown.
class _ShopStrip extends StatelessWidget {
  const _ShopStrip({required this.outfit});
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final brands = <String>{for (final piece in outfit.pieces) piece.brand};
    final first = brands.isEmpty ? 'DRIP' : brands.first;
    final extra = brands.length - 1;
    final total = outfit.pieces.isEmpty ? outfit.price : outfit.totalPrice;

    return Tap(
      onTap: () => context.push('/outfit/${outfit.id}'),
      semanticLabel: 'Shop the look: ${outfit.title}',
      scale: 0.98,
      child: Glass(
        radius: 16,
        thickness: GlassThickness.thin,
        shadow: false,
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHOP THE LOOK · ${outfit.pieces.length} PIECES',
                    style: AppText.mono(
                      9,
                      color: AppColors.muted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$first${extra > 0 ? ' +$extra' : ''}  ·  '
                    '${formatPriceShort(total)} total',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.manrope(12, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.cream,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── rail

class _ActionRail extends ConsumerWidget {
  const _ActionRail({required this.post});
  final Ootd post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.read(feedProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailButton(
          icon: post.isLiked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: post.isLiked ? AppColors.red : AppColors.cream,
          count: post.likes,
          active: post.isLiked,
          semantic: post.isLiked ? 'Unlike' : 'Like',
          onTap: () {
            Haptics.commit();
            feed.toggleLike(post.id);
          },
        ),
        _RailButton(
          icon: Icons.mode_comment_outlined,
          count: post.comments,
          semantic: 'Comments',
          onTap: () => showCommentsSheet(context, post.id),
        ),
        _RailButton(
          icon: post.isSaved
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
          color: post.isSaved ? context.palette.accent : AppColors.cream,
          count: post.saves,
          active: post.isSaved,
          semantic: post.isSaved ? 'Remove from saved' : 'Save',
          onTap: () {
            Haptics.commit();
            feed.toggleSave(post.id);
            showDripToast(
              context,
              post.isSaved ? 'Removed from saved' : 'Saved to your vault',
            );
          },
        ),
        _RailButton(
          icon: Icons.ios_share_rounded,
          count: post.shares,
          semantic: 'Share',
          onTap: () => showShareSheet(context, post),
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.count,
    required this.semantic,
    required this.onTap,
    this.color = AppColors.cream,
    this.active = false,
  });

  final IconData icon;
  final Color color;
  final int count;
  final bool active;
  final String semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Tap(
        onTap: onTap,
        scale: 0.88,
        semanticLabel: semantic,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Glass(
                  radius: 23,
                  thickness: GlassThickness.thin,
                  shadow: false,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Motion.quick,
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (c, a) =>
                          ScaleTransition(scale: a, child: c),
                      child: Icon(
                        icon,
                        key: ValueKey(icon),
                        size: 23,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCount(count),
                style: AppText.mono(10, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── loading

/// Loading placeholder: the same silhouette as a reel page.
class _ReelSkeleton extends StatelessWidget {
  const _ReelSkeleton();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ShimmerScope(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Skeleton(radius: 0),
          Positioned(
            left: 16,
            bottom: bottom + 10,
            right: 84,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Skeleton(width: 38, height: 38, circle: true),
                    SizedBox(width: 10),
                    Skeleton(width: 110, height: 14, radius: 7),
                  ],
                ),
                SizedBox(height: 16),
                Skeleton(width: 220, height: 20, radius: 8),
                SizedBox(height: 8),
                Skeleton(height: 12, radius: 6),
                SizedBox(height: 6),
                Skeleton(width: 180, height: 12, radius: 6),
                SizedBox(height: 16),
                Skeleton(height: 48, radius: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
