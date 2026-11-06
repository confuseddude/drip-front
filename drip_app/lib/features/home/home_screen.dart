import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../quiz/style_quiz.dart';
import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/contrast.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/image_tint.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../data/models/outfit.dart';
import '../../routing/main_shell.dart';
import '../bag/bag_controller.dart';
import '../bag/bag_sheet.dart';
import '../outfits/outfit_controller.dart';
import '../session/session_controller.dart';
import '../share/share_sheet.dart';
import '../social/social_controller.dart';
import 'feed_controller.dart';
import 'occasion_card.dart';
import 'occasions.dart';
import '../hints/hints.dart';

/// Home, the poster: a greeting with the live clock → today's pick on its own
/// colour → today's drip → (creators you follow) → four colour-block tools →
/// occasion posters → the board.
///
/// Every card that shows a fit wears that fit's own background colour, and
/// every fit has a send button: Drip grows through the chats people already
/// have, so sharing is never more than a tap away. There are no stories; the
/// one social loop is Studio fits, their likes and the board.
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
              error: (e, _) => ErrorState.from(
                e,
                onRetry: () => ref.invalidate(feedProvider),
              ),
              data: (state) => _HomeBody(fits: state.items),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────── header

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const DripWordmark(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              // Like Instagram: + opens the camera (swiping right does too).
              child: HintAnchor(
                id: 'home.camera',
                child: GlassIconButton(
                  semanticLabel: 'Open the camera',
                  onTap: openCamera(context),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 24,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GlassIconButton(
                semanticLabel: 'Activity',
                onTap: () => context.push('/activity'),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: AppColors.cream,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app's camera: garment capture, full screen. Opened from the + on Home
/// or by swiping right on Home.
VoidCallback openCamera(BuildContext context) =>
    () => context.push('/wardrobe/capture');

/// Opens the Scroll on [o]'s fits.
void _openOccasion(BuildContext context, Occasion o) {
  Haptics.tick();
  TabDirection.value = 1;
  context.push('/scroll?occasion=${o.id}');
}

/// Opens the Scroll on [fit] (or at the top).
void _openScroll(BuildContext context, [Outfit? fit]) {
  Haptics.tick();
  TabDirection.value = 1;
  context.go(fit == null ? '/scroll' : '/scroll?id=${fit.id}');
}

// ──────────────────────────────────────────────────────────────────── body

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.fits});
  final List<Outfit> fits;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(libraryProvider)
      ..invalidate(feedProvider);
    await ref.read(feedProvider.future);
    Haptics.tick();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pick = fits.isEmpty ? null : fits.first;
    final drip = fits.skip(1).take(8).toList();
    // The occasions picked in onboarding lead, tagged as theirs.
    final picked = ref.watch(onboardingProvider.select((p) => p.occasions));
    final occasions = Occasions.pickedFirst(picked);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      color: context.palette.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () => _refresh(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _Greeting(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _PickCard(outfit: pick),
            ),
          ),
          if (drip.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: _DripStrip(fits: drip, total: fits.length),
              ),
            ),
          // Creators arrive with the backend's follows; until then debug
          // builds show the layout with sample data, marked as such.
          if (kDebugMode)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 32, 16, 0),
                child: _YourPeople(),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 32, 16, 0),
              child: HintAnchor(id: 'home.tools', child: _Tools()),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
              child: HintAnchor(
                id: 'home.occasions',
                child: _SectionHead(
                  'SHOP BY OCCASION',
                  trailing: picked.isEmpty
                      ? null
                      : Text(
                          'YOURS FIRST',
                          style: AppText.mono(
                            10,
                            color: AppColors.cyan,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < occasions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    SizedBox(
                      width: 200,
                      height: 268,
                      child: OccasionCard(
                        occasion: occasions[i],
                        index: Occasions.all.indexOf(occasions[i]),
                        forYou: picked.contains(occasions[i].id),
                        onTap: () => _openOccasion(context, occasions[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 32, 16, bottom + 16),
              child: const _Board(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Bungee section title with an optional right-hand link.
class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: AppText.display(18))),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// A right-hand link for a section head.
class _HeadLink extends StatelessWidget {
  const _HeadLink(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: AppText.manrope(
            13,
            weight: FontWeight.w700,
            color: context.palette.accent,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────── greeting

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// The clock the Home greeting reads. Tests swap it to pin the time of day.
DateTime Function() homeClock = DateTime.now;

/// Date, time and day/night on one quiet line, then a big hello by the time
/// of day. Re-reads the clock on every minute change and follows the
/// phone's 12/24-hour setting.
class _Greeting extends ConsumerStatefulWidget {
  const _Greeting();

  @override
  ConsumerState<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends ConsumerState<_Greeting> {
  late DateTime _now = homeClock();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  /// Wakes on the next minute boundary, so the display is never a minute late.
  void _schedule() {
    final into = Duration(seconds: _now.second, milliseconds: _now.millisecond);
    _timer = Timer(const Duration(minutes: 1) - into, () {
      if (!mounted) return;
      setState(() => _now = homeClock());
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Daylight hours: 6 AM up to (not including) 6 PM.
  static bool _isDay(DateTime t) => t.hour >= 6 && t.hour < 18;

  static String _hello(DateTime t) => switch (t.hour) {
    >= 5 && < 12 => 'MORNING,',
    >= 12 && < 17 => 'AFTERNOON,',
    >= 17 && < 22 => 'EVENING,',
    _ => 'UP LATE,',
  };

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final p = context.palette;
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final day = _isDay(now);
    final date =
        '${_weekdays[now.weekday - 1]} · '
        '${now.day.toString().padLeft(2, '0')} ${_months[now.month - 1]}';
    final minute = now.minute.toString().padLeft(2, '0');
    final hour = h24
        ? now.hour.toString().padLeft(2, '0')
        : (now.hour % 12 == 0 ? 12 : now.hour % 12).toString();
    final period = h24 ? '' : (now.hour < 12 ? 'AM' : 'PM');
    final name = ref.watch(myProfileProvider).value?.name.trim() ?? '';
    final first = name.isEmpty ? '' : name.split(' ').first.toUpperCase();
    final meta = AppText.mono(11, color: AppColors.muted, letterSpacing: 1.2);

    return Semantics(
      label:
          '$date, $hour:$minute $period, ${day ? 'day' : 'night'}. '
          '${_hello(now)} ${first.isEmpty ? '' : first}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(date, style: meta),
              Text('  ·  ', style: meta),
              Text('$hour:$minute', style: meta),
              if (period.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(period, style: meta),
              ],
              Text('  ·  ', style: meta),
              Icon(
                day ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                size: 12,
                color: p.accent,
              ),
              const SizedBox(width: 4),
              Text(day ? 'DAY' : 'NIGHT', style: meta),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: _hello(now),
              children: [
                if (first.isNotEmpty)
                  TextSpan(
                    text: '\n$first.',
                    style: TextStyle(color: p.accent),
                  ),
              ],
            ),
            style: AppText.display(32, lineHeight: 35),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────── today's pick

/// Today's pick, on its own colour: the flat-lay whole, a sticker, the name,
/// pieces and price, Ask Taylor and a send button. With nothing to pick yet
/// it's the door to Taylor.
class _PickCard extends StatelessWidget {
  const _PickCard({required this.outfit});
  final Outfit? outfit;

  @override
  Widget build(BuildContext context) {
    final fit = outfit;
    if (fit == null) return const _TaylorCard();
    final p = context.palette;
    final radius = (30 * p.roundness).clamp(18.0, 32.0);
    final n = fit.pieces.length;
    return ImageTint(
      image: fit.image,
      fallback: AppColors.cream,
      builder: (context, tint) {
        final ink = inkOn(tint);
        return Tap(
          onTap: () => _openScroll(context, fit),
          semanticLabel: "Today's pick: ${fit.title}. Open it",
          scale: 0.99,
          child: Container(
            height: 452,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: 6,
                  top: 12,
                  bottom: 76,
                  width: 230,
                  child: DripImage(
                    fit.image,
                    fit: BoxFit.contain,
                    backdrop: false,
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: _Label("TODAY'S PICK", bg: ink, ink: tint),
                ),
                Positioned(
                  left: 14,
                  top: 62,
                  child: _Sticker('PICKED\nFOR YOU', bg: p.accent),
                ),
                Positioned(
                  left: 18,
                  bottom: 84,
                  width: 128,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fit.title.toUpperCase(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(20, color: ink, lineHeight: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (n > 0) '$n ${n == 1 ? 'piece' : 'pieces'}',
                          if (fit.price > 0) formatPrice(fit.price),
                        ].join('\n'),
                        style: AppText.manrope(
                          13,
                          weight: FontWeight.w700,
                          color: ink,
                          lineHeight: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Tap(
                          onTap: () => context.push('/stylist'),
                          semanticLabel: 'Ask Taylor',
                          scale: 0.97,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: ink,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _TaylorFace(size: 26),
                                const SizedBox(width: 8),
                                Text(
                                  'Ask Taylor',
                                  style: AppText.manrope(
                                    14,
                                    weight: FontWeight.w800,
                                    color: tint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SendCircle(
                        ink: ink,
                        size: 52,
                        onTap: () => showShareFit(context, fit),
                      ),
                    ],
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

/// Before there's a pick: Taylor plans the look.
class _TaylorCard extends StatelessWidget {
  const _TaylorCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tap(
      onTap: () => context.push('/stylist'),
      semanticLabel: 'Ask Taylor',
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cream.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            const _TaylorFace(size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR STYLIST',
                    style: AppText.mono(10, color: AppColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Plan a look for today',
                    style: AppText.manrope(15, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Text(
              'Ask Taylor',
              style: AppText.manrope(
                13,
                weight: FontWeight.w800,
                color: p.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaylorFace extends StatelessWidget {
  const _TaylorFace({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: DripImage(
          'assets/images/avatar_taylor_ai.jpg',
          logicalWidth: size,
        ),
      ),
    );
  }
}

/// A small dark label, like a price tag.
class _Label extends StatelessWidget {
  const _Label(this.text, {required this.bg, required this.ink});
  final String text;
  final Color bg;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: AppText.mono(10, color: ink, letterSpacing: 1)),
    );
  }
}

/// A tilted sticker in the accent, the poster's one bit of mischief.
class _Sticker extends StatelessWidget {
  const _Sticker(this.text, {required this.bg, this.angle = -0.12});
  final String text;
  final Color bg;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          style: AppText.display(11, color: inkOn(bg), lineHeight: 13),
        ),
      ),
    );
  }
}

/// The send button on a fit card.
class _SendCircle extends StatelessWidget {
  const _SendCircle({required this.ink, required this.onTap, this.size = 32});
  final Color ink;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: 'Send',
      scale: 0.9,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ink.withValues(alpha: size > 40 ? 0.08 : 0.12),
          border: size > 40 ? Border.all(color: ink, width: 1.5) : null,
        ),
        child: Icon(Icons.send_outlined, size: size * 0.42, color: ink),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────── today's drip

/// The next fits in the feed as colour tiles, into the Scroll.
class _DripStrip extends StatelessWidget {
  const _DripStrip({required this.fits, required this.total});
  final List<Outfit> fits;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionHead(
            "TODAY'S DRIP",
            trailing: _HeadLink(
              '$total fresh · watch',
              onTap: () => _openScroll(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: fits.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _DripTile(outfit: fits[i]),
          ),
        ),
      ],
    );
  }
}

class _DripTile extends StatelessWidget {
  const _DripTile({required this.outfit});
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    return ImageTint(
      image: outfit.image,
      fallback: AppColors.elevated,
      builder: (context, tint) {
        final ink = inkOn(tint);
        return Tap(
          onTap: () => _openScroll(context, outfit),
          semanticLabel: outfit.title,
          scale: 0.97,
          child: Container(
            width: 148,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 40,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: DripImage(
                      outfit.image,
                      fit: BoxFit.contain,
                      backdrop: false,
                      logicalWidth: 148,
                    ),
                  ),
                ),
                if (outfit.price > 0)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        formatPrice(outfit.price),
                        style: AppText.manrope(
                          12,
                          weight: FontWeight.w800,
                          color: tint,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _SendCircle(
                    ink: ink,
                    onTap: () => showShareFit(context, outfit),
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

// ──────────────────────────────────────────────────────────── your people

/// Sample creators: debug builds only, until follows come from the backend.
class _Sample {
  const _Sample(
    this.handle,
    this.category,
    this.likes,
    this.tint,
    this.avatar,
    this.pieces,
  );
  final String handle;
  final String category;
  final String likes;
  final Color tint;
  final String avatar;
  final List<String> pieces;
}

const _samples = [
  _Sample(
    'sofiamae',
    'DATE NIGHT',
    '1.2k',
    Color(0xFFF5D6C3),
    'assets/images/story_sofiamae.jpg',
    [
      'assets/images/piece_bomber.jpg',
      'assets/images/wardrobe_crop_puff.jpg',
      'assets/images/wardrobe_vintage_hoodie.jpg',
      'assets/images/wardrobe_chunky_boots.jpg',
    ],
  ),
  _Sample(
    'parismoto',
    'CONCERTS',
    '864',
    Color(0xFFD3E4F3),
    'assets/images/story_parismoto.jpg',
    [
      'assets/images/piece_shell_jacket.jpg',
      'assets/images/piece_tactical_vest.jpg',
      'assets/images/piece_cyber_overcoat.jpg',
      'assets/images/wardrobe_chunky_boots.jpg',
    ],
  ),
];

class _YourPeople extends StatelessWidget {
  const _YourPeople();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _SectionHead(
            'NEW FROM\nYOUR PEOPLE',
            trailing: Text(
              'SAMPLE',
              style: AppText.mono(10, color: AppColors.muted, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < _samples.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _PersonCard(sample: _samples[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.sample});
  final _Sample sample;

  @override
  Widget build(BuildContext context) {
    final s = sample;
    final ink = inkOn(s.tint);
    Widget piece(String src, double size) => SizedBox(
      width: size,
      height: size,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(s.tint, BlendMode.multiply),
        child: DripImage(src, fit: BoxFit.contain, backdrop: false),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 232,
          decoration: BoxDecoration(
            color: s.tint,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(left: 10, top: 16, child: piece(s.pieces[0], 90)),
              Positioned(right: 8, top: 32, child: piece(s.pieces[1], 68)),
              Positioned(left: 20, top: 112, child: piece(s.pieces[2], 84)),
              Positioned(right: 12, top: 122, child: piece(s.pieces[3], 64)),
              Positioned(
                left: 10,
                top: 10,
                child: _Sticker(
                  'NEW',
                  bg: context.palette.accent,
                  angle: -0.09,
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 11,
                        color: AppColors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.likes,
                        style: AppText.manrope(
                          11.5,
                          weight: FontWeight.w800,
                          color: s.tint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 24,
                height: 24,
                child: DripImage(s.avatar, logicalWidth: 24),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${s.handle}',
                    style: AppText.manrope(13, weight: FontWeight.w800),
                  ),
                  Text(
                    s.category,
                    style: AppText.mono(10, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────── tools

class _Feature {
  const _Feature(this.index, this.icon, this.label);
  final String index;
  final IconData icon;
  final String label;
}

const _features = [
  _Feature('01', Icons.face_retouching_natural_rounded, 'Selfie Coordinator'),
  _Feature('02', Icons.palette_outlined, 'Colour Theory'),
  _Feature('03', Icons.shopping_bag_outlined, 'Shop List'),
  _Feature('04', Icons.quiz_outlined, 'Style Quiz'),
];

/// Four tools as colour blocks: the accent, cream, the secondary and ink.
class _Tools extends ConsumerWidget {
  const _Tools();

  void _open(BuildContext context, _Feature f) {
    switch (f.index) {
      case '01':
        context.push('/selfie');
      case '02':
        context.push('/me/colour-theory');
      case '03':
        showBagSheet(context);
      case '04':
        context.push('/quiz');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final inBag = ref.watch(bagProvider).length;
    final quizDone = ref.watch(quizAnswersProvider).isNotEmpty;
    final metas = {
      '01': 'Guided selfie',
      '02': 'Your palette',
      '03': inBag == 0 ? 'Bag is empty' : '$inBag in your bag',
      '04': quizDone ? 'Retake it' : '10 quick taps',
    };
    final grounds = {
      '01': p.accent,
      '02': AppColors.cream,
      '03': p.secondary,
      '04': AppColors.surface,
    };
    Widget tile(_Feature f) => Expanded(
      child: _ToolTile(
        feature: f,
        meta: metas[f.index]!,
        ground: grounds[f.index]!,
        outlined: f.index == '04',
        onTap: () => _open(context, f),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: _SectionHead('YOUR TOOLS'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            tile(_features[0]),
            const SizedBox(width: 10),
            tile(_features[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            tile(_features[2]),
            const SizedBox(width: 10),
            tile(_features[3]),
          ],
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.feature,
    required this.meta,
    required this.ground,
    required this.outlined,
    required this.onTap,
  });
  final _Feature feature;
  final String meta;
  final Color ground;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = (24 * context.palette.roundness).clamp(14.0, 26.0);
    // Ink chosen for the block, then checked, whatever the theme's colours.
    final ink = ensureContrast(inkOn(ground), ground, minRatio: 4.5);
    final soft = ink.withValues(alpha: 0.78);
    return Tap(
      onTap: onTap,
      semanticLabel: feature.label,
      scale: 0.97,
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ground,
          borderRadius: BorderRadius.circular(radius),
          border: outlined
              ? Border.all(
                  color: AppColors.cream.withValues(alpha: 0.22),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(feature.icon, size: 28, color: ink),
                const Spacer(),
                Text(feature.index, style: AppText.mono(10, color: soft)),
              ],
            ),
            const Spacer(),
            Text(
              feature.label,
              maxLines: 2,
              style: AppText.display(14, color: ink, lineHeight: 16),
            ),
            const SizedBox(height: 3),
            Text(
              meta,
              style: AppText.manrope(12, weight: FontWeight.w600, color: soft),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── board

const _board = [
  ('1', 'lxnafits', '4,820', 'assets/images/story_lxnafits.jpg'),
  ('2', 'sofiamae', '3,910', 'assets/images/story_sofiamae.jpg'),
  ('3', 'parismoto', '3,302', 'assets/images/story_parismoto.jpg'),
];

/// The game: the week's top creators (sample rows in debug builds until the
/// backend keeps scores), and the way onto the board.
class _Board extends StatelessWidget {
  const _Board();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kDebugMode)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.cream.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHead(
                  'THE BOARD',
                  trailing: Text(
                    'SAMPLE · THIS WEEK',
                    style: AppText.mono(10, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Likes on Studio fits make the score.',
                  style: AppText.manrope(13, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                for (final (rank, handle, score, avatar) in _board)
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.cream.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            rank,
                            style: AppText.display(
                              18,
                              color: rank == '1' ? p.accent : AppColors.cream,
                            ),
                          ),
                        ),
                        ClipOval(
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: DripImage(avatar, logicalWidth: 38),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@$handle',
                                style: AppText.manrope(
                                  14,
                                  weight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '$score PTS',
                                style: AppText.mono(10, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (kDebugMode) const SizedBox(height: 10),
        Tap(
          onTap: () {
            TabDirection.value = 1;
            context.go('/studio');
          },
          semanticLabel: 'Post a fit, climb the board',
          scale: 0.98,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POST A FIT, CLIMB THE BOARD',
                        style: AppText.display(15, color: inkOn(p.accent)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Make it in Studio, tag it, post it.',
                        style: AppText.manrope(
                          12.5,
                          weight: FontWeight.w600,
                          color: inkOn(p.accent).withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: inkOn(p.accent)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────── loading state

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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Skeleton(width: 220, height: 64, radius: 12),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Skeleton(width: width, height: 452, radius: 30),
            ),
          ],
        ),
      ),
    );
  }
}
