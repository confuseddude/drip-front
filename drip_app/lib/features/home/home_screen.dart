import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/fit_hero.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../data/mock/mock_weather.dart';
import '../../data/models/ootd.dart';
import '../../data/models/outfit.dart';
import '../../routing/main_shell.dart';
import '../activity/activity_controller.dart';
import '../outfits/outfit_controller.dart';
import '../social/social_controller.dart';
import 'feed_controller.dart';

/// Home: brand + actions → today's weather/outfit hero → feature blocks →
/// stories → today's-drip bar → a two-column grid of fresh fits.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);

    return ShellPage(
      child: Column(
        children: [
          const _HomeHeader(),
          Expanded(
            child: feed.when(
              // Placeholders shaped like the real layout, not a spinner.
              loading: () => const _HomeSkeleton(),
              error: (_, _) =>
                  ErrorState(onRetry: () => ref.invalidate(feedProvider)),
              data: (posts) => posts.isEmpty
                  ? const EmptyState(
                      title: 'NOTHING YET',
                      message: 'Follow more creators to fill your feed.',
                    )
                  : _HomeBody(posts: posts),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens a fit in the Fashion Scroll from a card. The image expands into place
/// (Hero), so the page itself must not slide: direction 0 means "no tab move".
void _openInScroll(BuildContext context, String id) {
  TabDirection.value = 0;
  context.push('/scroll?id=$id');
}

// ───────────────────────────────────────────────────────────────── header

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(activityProvider)
        .maybeWhen(
          data: (items) => items.where((a) => !a.isRead).length,
          orElse: () => 0,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const DripWordmark(height: 30),
            const Spacer(),
            GlassIconButton(
              semanticLabel: unread > 0
                  ? 'Messages and notifications, $unread new'
                  : 'Messages and notifications',
              onTap: () => context.push('/activity'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 20,
                    color: AppColors.cream,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: context.palette.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.base, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── body

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.posts});
  final List<Ootd> posts;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(storiesProvider);
    ref.invalidate(feedProvider);
    await ref.read(feedProvider.future);
    Haptics.tick();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(outfitCatalogProvider).value ?? const <Outfit>[];
    final shownImages = {for (final p in posts) p.image};
    final looks = [
      for (final o in catalog)
        if (!shownImages.contains(o.image)) o,
    ].take(6).toList();
    final todaysPick = catalog.isEmpty ? null : catalog.first;

    final tiles = <_GridItem>[
      for (final p in posts)
        _GridItem(
          key: p.id,
          image: p.image,
          title: p.title,
          handle: p.creatorHandle,
          score: p.score,
          likes: p.likes,
          heroId: p.id,
          onTap: () => _openInScroll(context, p.id),
        ),
      for (final o in looks)
        _GridItem(
          key: o.id,
          image: o.image,
          title: o.title,
          handle: o.creatorHandle,
          score: o.rate,
          likes: null,
          onTap: () => context.push('/outfit/${o.id}'),
        ),
    ];

    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      color: context.palette.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () => _refresh(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _StoriesStrip()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _WeatherHeroCard(outfit: todaysPick),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _FeatureBlocksRow(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _DripBar(count: posts.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Row(
                children: [
                  Text(
                    'FRESH FITS',
                    style: AppText.mono(
                      11,
                      color: AppColors.muted,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const Spacer(),
                  Tap(
                    onTap: () => context.push('/discover'),
                    semanticLabel: 'Search and discover fits',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'SEARCH & DISCOVER  →',
                        style: AppText.mono(
                          10,
                          color: context.palette.accent,
                          weight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _GridTile(item: tiles[i]),
                childCount: tiles.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────── stories

class _StoriesStrip extends ConsumerWidget {
  const _StoriesStrip();

  static const _avatar = 76.0;
  static const _height = 118.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);
    final me = ref.watch(myProfileProvider).value;
    return SizedBox(
      height: _height,
      child: stories.when(
        loading: () => const _StoriesSkeleton(),
        error: (_, _) => Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Tap(
              onTap: () => ref.invalidate(storiesProvider),
              child: Text(
                "COULDN'T LOAD STORIES · TAP TO RETRY",
                style: AppText.mono(9, color: AppColors.red),
              ),
            ),
          ),
        ),
        data: (list) => ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          itemCount: list.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _StoryBubble(
                label: 'Your story',
                avatar: me?.avatar,
                isYou: true,
                onTap: () => context.push('/create'),
              );
            }
            final s = list[i - 1];
            return _StoryBubble(
              label: s.handle,
              avatar: s.avatar,
              unseen: s.unseen,
              onTap: () {
                final id = s.ootdId;
                if (id == null) return;
                ref.read(storiesProvider.notifier).markSeen(s.handle);
                Haptics.tick();
                context.push('/ootd/$id');
              },
            );
          },
        ),
      ),
    );
  }
}

/// A story: bigger than the old bubbles, with an accent→secondary ring when
/// unseen and a hairline ring once seen, so state never depends on colour
/// alone (the ring is also thicker).
class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.label,
    required this.avatar,
    required this.onTap,
    this.unseen = false,
    this.isYou = false,
  });

  final String label;
  final String? avatar;
  final bool unseen;
  final bool isYou;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const size = _StoriesStrip._avatar;
    return Tap(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: isYou
          ? 'Add to your story'
          : '$label story${unseen ? ', new' : ''}',
      child: SizedBox(
        width: size + 4,
        child: Column(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    padding: EdgeInsets.all(unseen ? 3 : 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: unseen
                          ? SweepGradient(
                              colors: [
                                p.accent,
                                p.secondary,
                                p.accent,
                                p.secondary,
                                p.accent,
                              ],
                            )
                          : null,
                      color: unseen ? null : AppColors.elevated,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.base,
                      ),
                      child: ClipOval(
                        child: avatar == null
                            ? ColoredBox(color: AppColors.elevated)
                            : DripImage(avatar!, logicalWidth: size),
                      ),
                    ),
                  ),
                  if (isYou)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: p.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.base, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: AppColors.base,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isYou ? label : '@$label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.manrope(
                11,
                weight: unseen ? FontWeight.w700 : FontWeight.w500,
                color: unseen ? AppColors.cream : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── weather hero

/// The Home hero: today's mocked weather, a palette swatch coordinated with
/// the active theme skin, and a suggested outfit. Tap opens Ask Taylor —
/// "what to wear today" leads straight into the stylist.
class _WeatherHeroCard extends StatelessWidget {
  const _WeatherHeroCard({required this.outfit});
  final Outfit? outfit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final weather = MockWeather.today();
    final corner = (28 * p.roundness).clamp(14.0, 32.0);
    final swatches = [p.accent, p.secondary, p.wash, AppColors.cream];

    return Tap(
      onTap: () => context.push('/stylist'),
      semanticLabel: "Today's weather and outfit pick, ask Taylor",
      scale: 0.98,
      child: Glass(
        radius: corner,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S WEATHER",
                        style: AppText.mono(
                          10,
                          color: AppColors.muted,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(weather.glyph, style: AppText.display(26)),
                          const SizedBox(width: 10),
                          Text(
                            '${weather.tempF}°  ${weather.condition}',
                            style: AppText.display(16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (final c in swatches)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              weather.advice,
              style: AppText.manrope(
                13,
                color: AppColors.cream.withValues(alpha: 0.85),
                lineHeight: 18,
              ),
            ),
            if (outfit != null) ...[
              const SizedBox(height: 14),
              Glass(
                radius: 16,
                thickness: GlassThickness.thin,
                shadow: false,
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: DripImage(
                          outfit!.image,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "TODAY'S PICK",
                            style: AppText.mono(
                              9,
                              color: AppColors.muted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            outfit!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.manrope(13, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '✦ ASK TAYLOR',
                      style: AppText.mono(
                        9,
                        color: p.accent,
                        weight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── feature blocks

class _FeatureBlock {
  const _FeatureBlock(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _featureBlocks = [
  _FeatureBlock(Icons.face_retouching_natural_rounded, 'Selfie Coordinator'),
  _FeatureBlock(Icons.palette_outlined, 'Color Theory'),
  _FeatureBlock(Icons.shopping_bag_outlined, 'Shop List'),
  _FeatureBlock(Icons.quiz_outlined, 'Style Quiz'),
];

/// Mock feature entry points, 2×2. These aren't wired to real screens yet —
/// tapping just says so, honestly, instead of faking a destination.
class _FeatureBlocksRow extends StatelessWidget {
  const _FeatureBlocksRow();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _featureBlocks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, i) {
        final f = _featureBlocks[i];
        final p = context.palette;
        return Tap(
          onTap: () => showDripToast(context, 'Coming soon'),
          semanticLabel: f.label,
          scale: 0.97,
          child: Glass(
            radius: 16,
            thickness: GlassThickness.thin,
            shadow: false,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(f.icon, size: 18, color: p.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mono(
                      10,
                      weight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────── info bar

/// The wide bar under the featured fit: a quiet daily summary plus the
/// stylist entry point (moved here from the header so the header can stay
/// brand + two actions).
class _DripBar extends StatelessWidget {
  const _DripBar({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Glass(
      radius: 22,
      thickness: GlassThickness.thin,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S DRIP",
                  style: AppText.mono(
                    10,
                    color: AppColors.muted,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count fits from creators you follow',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.manrope(13, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tap(
            onTap: () => context.push('/stylist'),
            semanticLabel: 'Ask Taylor, your stylist',
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: 0.32),
                  width: 0.75,
                ),
              ),
              child: Text(
                '✦ ASK TAYLOR',
                style: AppText.mono(
                  10,
                  color: accent,
                  weight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── grid

class _GridItem {
  const _GridItem({
    required this.key,
    required this.image,
    required this.title,
    required this.handle,
    required this.score,
    required this.likes,
    required this.onTap,
    this.heroId,
  });

  final String key;
  final String image;
  final String title;
  final String handle;
  final int score;
  final int? likes;
  final String? heroId;
  final VoidCallback onTap;
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.item});
  final _GridItem item;

  @override
  Widget build(BuildContext context) {
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(
        (22 * context.palette.roundness).clamp(12.0, 26.0),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DripImage(item.image, alignment: Alignment.topCenter),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0xCC0E1018), Color(0x000E1018)],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.manrope(
                    13,
                    weight: FontWeight.w700,
                    lineHeight: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.likes == null
                      ? '@${item.handle}'
                      : '@${item.handle} · ♥ ${formatCount(item.likes!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mono(
                    9,
                    color: AppColors.cream.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            // Plain translucent chip: many tiles scroll at once, so no
            // per-tile backdrop blur here.
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.base.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Text('${item.score}', style: AppText.display(10)),
            ),
          ),
        ],
      ),
    );

    return Tap(
      onTap: item.onTap,
      scale: 0.97,
      semanticLabel: '${item.title} by ${item.handle}',
      child: item.heroId == null
          ? photo
          : FitHero(ootdId: item.heroId!, radius: 22, child: photo),
    );
  }
}

// ──────────────────────────────────────────────────────────── loading state

class _StoriesSkeleton extends StatelessWidget {
  const _StoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => const Column(
          children: [
            Skeleton(width: 76, height: 76, circle: true),
            SizedBox(height: 8),
            Skeleton(width: 52, height: 9, radius: 5),
          ],
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32;
    return ShimmerScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: _StoriesStrip._height,
              child: _StoriesSkeleton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Skeleton(width: width, height: width * 1.06, radius: 28),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Skeleton(width: width, height: 64, radius: 22),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Skeleton(height: (width / 2) / 0.76, radius: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Skeleton(height: (width / 2) / 0.76, radius: 22),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
