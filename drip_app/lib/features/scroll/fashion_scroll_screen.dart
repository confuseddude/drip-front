import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/image_color.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/fit_hero.dart';
import '../../core/widgets/like_burst.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/slide_up_sheet.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/tap.dart';
import '../../data/models/outfit.dart';
import '../home/feed_controller.dart';
import '../home/occasions.dart';
import '../outfits/fit_actions.dart';
import '../outfits/outfit_controller.dart';
import '../outfits/shop_sheet.dart';
import '../report/report_bug_sheet.dart';
import '../share/share_sheet.dart';
import '../../core/widgets/image_tint.dart';
import 'fit_pieces_sheet.dart';
import 'reel_physics.dart';
import 'shop_the_look.dart';
import '../hints/hints.dart';

/// The Fashion Scroll: full-screen, one fit at a time, snapping vertically.
///
/// Fits come a page at a time from `GET /scroll` (ranked, not seen before);
/// the next page loads as you near the end, and the last page is a
/// "caught up" card. Each card reports how long it was on screen (`open` or
/// `skip`), which trains the ranking.
///
/// Only the visible page is built (`PageView.builder`), the next images are
/// pre-cached, and everything laid over the photo is either a gradient or a
/// small glass element, so the photograph stays the hero. A post's details
/// stay folded away until its caption is tapped.
class FashionScrollScreen extends ConsumerStatefulWidget {
  const FashionScrollScreen({super.key, this.startId, this.occasion});

  /// Fit to open on (from Home). Null starts at the top of the feed.
  final String? startId;

  /// Only fits that suit this occasion (an `Occasions` id), from Home's
  /// occasion cards. Null is the full feed.
  final String? occasion;

  @override
  ConsumerState<FashionScrollScreen> createState() =>
      _FashionScrollScreenState();
}

class _FashionScrollScreenState extends ConsumerState<FashionScrollScreen> {
  /// A card viewed at least this long counts as `open`, else `skip`.
  static const _openAfter = Duration(milliseconds: 2000);

  /// Start loading the next page this many cards before the end.
  static const _prefetch = 3;

  /// The feed this Scroll reads: the full one, or an occasion's.
  late final _feedProvider = scrollFeedProvider(widget.occasion);

  PageController? _pc;
  int _page = 0;

  /// Where the next swipe is measured from (see [ReelPhysics]).
  final _paging = ReelPaging();
  String? _viewingId;
  final _viewing = Stopwatch();

  /// Held so the last card can still be reported from [dispose], when `ref`
  /// can no longer be used.
  FeedController? _feed;

  @override
  void dispose() {
    _reportView();
    _pc?.dispose();
    super.dispose();
  }

  PageController _controllerFor(List<Outfit> items) {
    if (_pc != null) return _pc!;
    final start = widget.startId == null
        ? 0
        : items
              .indexWhere((o) => o.id == widget.startId)
              .clamp(0, items.length);
    _page = start;
    _paging.page = start;
    return _pc = PageController(initialPage: _page);
  }

  void _precache(List<Outfit> items, int i) {
    for (final j in [i + 1, i + 2]) {
      if (j < items.length && items[j].image.isNotEmpty) {
        precacheImage(dripImageProvider(items[j].image), context);
      }
    }
  }

  /// Starts timing the card now on screen (reporting the previous one).
  void _startViewing(List<Outfit> items, int i) {
    final id = i < items.length ? items[i].id : null;
    if (id == _viewingId) return;
    _reportView();
    _feed = ref.read(_feedProvider.notifier);
    _viewingId = id;
    _viewing
      ..reset()
      ..start();
  }

  void _reportView() {
    final id = _viewingId;
    if (id == null) return;
    final dwell = _viewing.elapsed;
    _viewingId = null;
    _feed?.signal(
      id,
      dwell >= _openAfter ? 'open' : 'skip',
      dwellMs: dwell.inMilliseconds,
    );
  }

  void _onPage(FeedState feed, int i) {
    setState(() => _page = i);
    _precache(feed.items, i);
    _startViewing(feed.items, i);
    if (i >= feed.items.length - _prefetch) {
      ref.read(_feedProvider.notifier).loadMore();
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// Opens the Scroll on [id]'s fits (all fits when null), in place of this
  /// one.
  void _openOccasion(String? id) {
    if (id == widget.occasion) return;
    Haptics.tick();
    final to = id == null ? '/scroll' : '/scroll?occasion=$id';
    if (context.canPop()) {
      context.pushReplacement(to);
    } else {
      context.go(to);
    }
  }

  void _pickOccasion() => showOccasionPicker(
    context,
    current: widget.occasion,
    onPick: _openOccasion,
  );

  void _toTop() {
    Haptics.tick();
    _pc?.animateToPage(0, duration: Motion.page, curve: Motion.out);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(_feedProvider);
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        // Reached via the tab (no Home underneath): back goes Home, not out.
        if (!didPop) context.go('/home');
      },
      child: feed.when(
        loading: () => const _ReelSkeleton(),
        error: (e, _) =>
            ErrorState.from(e, onRetry: () => ref.invalidate(_feedProvider)),
        data: (state) {
          final items = state.items;
          final occasion = Occasions.byId(widget.occasion);
          if (items.isEmpty && occasion != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                EmptyState(
                  title: 'NOTHING FOR ${occasion.label.toUpperCase()} YET',
                  message:
                      'No fits in the catalogue suit this one yet. More '
                      'land every day.',
                  actionLabel: 'BROWSE EVERYTHING',
                  onAction: () => _openOccasion(null),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopChrome(
                    onBack: context.canPop() ? _back : null,
                    label: occasion.label,
                    onPick: _pickOccasion,
                  ),
                ),
              ],
            );
          }
          if (items.isEmpty) {
            return EmptyState(
              title: 'FRESH FITS INCOMING',
              message:
                  "Drip's catalogue is still being stocked. New fits land "
                  "here as soon as they're ready.",
              actionLabel: 'CHECK AGAIN',
              onAction: () => ref.invalidate(_feedProvider),
            );
          }
          final pc = _controllerFor(items);
          if (_viewingId == null && _page < items.length) {
            _startViewing(items, _page);
            _precache(items, _page);
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollEndNotification>(
                onNotification: (n) {
                  if (n.depth == 0) _paging.settle(n.metrics);
                  return false;
                },
                child: PageView.builder(
                  controller: pc,
                  scrollDirection: Axis.vertical,
                  // One swipe, one fit: ReelPhysics does the snapping.
                  pageSnapping: false,
                  physics: ReelPhysics(
                    _paging,
                    parent: const ClampingScrollPhysics(),
                  ),
                  // The fit after this one is built (and its picture decoded)
                  // before the swipe, so it slides in ready.
                  allowImplicitScrolling: true,
                  itemCount: items.length + 1,
                  onPageChanged: (i) => _onPage(state, i),
                  itemBuilder: (context, i) => i < items.length
                      ? _Depth(
                          controller: pc,
                          index: i,
                          child: _ReelPage(
                            key: ValueKey(items[i].id),
                            outfit: items[i],
                            active: i == _page,
                          ),
                        )
                      : _FeedTail(
                          state: state,
                          onRetry: () =>
                              ref.read(_feedProvider.notifier).loadMore(),
                          onTop: _toTop,
                        ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopChrome(
                  onBack: context.canPop() ? _back : null,
                  label: occasion?.label,
                  onPick: _pickOccasion,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The page after the last fit: loading the next page, a retry, or the end.
class _FeedTail extends StatelessWidget {
  const _FeedTail({
    required this.state,
    required this.onRetry,
    required this.onTop,
  });
  final FeedState state;
  final VoidCallback onRetry;
  final VoidCallback onTop;

  @override
  Widget build(BuildContext context) {
    if (state.hasMore && !state.loadMoreFailed) {
      return const _ReelSkeleton();
    }
    if (state.loadMoreFailed) {
      return ErrorState(message: "Couldn't load more fits.", onRetry: onRetry);
    }
    return EmptyState(
      title: "YOU'RE ALL CAUGHT UP",
      message: "That's every fresh fit for now. More drop soon.",
      actionLabel: 'BACK TO THE TOP',
      onAction: onTop,
    );
  }
}

// ────────────────────────────────────────────────────────────────── chrome

/// The Scroll's top bar: back (when there's somewhere to go back to) and the
/// occasion being browsed, as a pill that opens the occasion picker.
///
/// Solid tinted surfaces, never live blur: a blur here would be redrawn every
/// frame of every swipe underneath it, the main cause of jank on mid-range
/// Android phones.
class _TopChrome extends StatelessWidget {
  const _TopChrome({required this.onBack, required this.onPick, this.label});

  final VoidCallback? onBack;
  final VoidCallback onPick;

  /// The occasion being browsed; null is every fit.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 16, 0),
        child: Row(
          children: [
            if (onBack != null) ...[
              Tap(
                onTap: onBack,
                scale: 0.92,
                semanticLabel: 'Back',
                child: const _Scrim(
                  width: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 17,
                    color: AppColors.cream,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Tap(
              onTap: onPick,
              scale: 0.96,
              semanticLabel:
                  '${label == null ? 'All occasions' : 'Fits for $label'}. '
                  'Change the occasion',
              child: _Scrim(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label ?? 'All occasions',
                      style: AppText.manrope(13, weight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.cream,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dark, see-through pill that reads on any picture (pale flat-lays too)
/// without blurring what's under it.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.child, this.width, this.padding});
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 44,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.base.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }
}

/// Every occasion, to switch the Scroll to; [current] is ticked.
void showOccasionPicker(
  BuildContext context, {
  required String? current,
  required ValueChanged<String?> onPick,
}) {
  final accent = context.palette.accent;
  Widget row(BuildContext ctx, String? id, String label, String line) {
    final on = id == current;
    return Tap(
      onTap: () {
        Navigator.of(ctx).pop();
        onPick(id);
      },
      semanticLabel: on ? '$label, showing now' : label,
      scale: 0.98,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.manrope(
                      15,
                      weight: FontWeight.w700,
                      color: on ? accent : AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line,
                    style: AppText.manrope(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (on) Icon(Icons.check_rounded, size: 20, color: accent),
          ],
        ),
      ),
    );
  }

  showDripSheet<void>(
    context,
    builder: (ctx) => SheetContent(
      title: 'FITS FOR',
      children: [
        row(ctx, null, 'All occasions', 'Everything, ranked for you'),
        for (final o in Occasions.all) row(ctx, o.id, o.label, o.line),
      ],
    ),
  );
}

/// Depth on the way out: the fit you swipe away sinks back a little and
/// dims, so the next one reads as coming over it.
class _Depth extends StatelessWidget {
  const _Depth({
    required this.controller,
    required this.index,
    required this.child,
  });
  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Its own layer: the page underneath isn't repainted as this one moves.
    final page = RepaintBoundary(child: child);
    if (Motion.reduced(context)) return page;
    return AnimatedBuilder(
      animation: controller,
      child: page,
      builder: (context, child) {
        final at = controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? index.toDouble()
            : index.toDouble();
        final out = (at - index).clamp(0.0, 1.0);
        // The same widgets every frame (only their values change), so the
        // page keeps its state while it moves.
        return Transform.scale(
          scale: 1 - 0.06 * out,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28 * out),
            clipBehavior: out > 0 ? Clip.antiAlias : Clip.none,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child!,
                IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45 * out),
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

// ──────────────────────────────────────────────────────────────────── page

/// One fit, full screen. The picture is the hero: at rest only who posted it,
/// a one-line caption and a slim rail of actions sit on top. Tapping the
/// caption opens the details (tags, shop the look, price, score) in place, the
/// way Instagram opens a long caption; tapping the picture or swiping to the
/// next fit closes them again.
///
/// A collage is a flat-lay, so it is shown whole inside the space the chrome
/// leaves (never cropped, never under the rail or the info), and the space
/// around it takes the collage's own background colour. An on-body photo stays
/// full-bleed with the chrome over a soft scrim.
class _ReelPage extends ConsumerStatefulWidget {
  const _ReelPage({super.key, required this.outfit, required this.active});
  final Outfit outfit;
  final bool active;

  @override
  ConsumerState<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends ConsumerState<_ReelPage> {
  int _burst = 0;
  bool _expanded = false;

  /// Shop the look: the sheet is open on this spot's piece.
  int? _shopAt;
  late List<ShopSpot> _spots = shopSpots(widget.outfit);

  /// The collage's background colour, once its picture has decoded.
  Color? _bg;

  @override
  void didUpdateWidget(_ReelPage old) {
    super.didUpdateWidget(old);
    // Leaving a card closes its details.
    if (old.active && !widget.active) {
      _expanded = false;
      _shopAt = null;
    }
    if (!identical(old.outfit, widget.outfit)) {
      _spots = shopSpots(widget.outfit);
      _shopAt = null;
    }
  }

  void _openShop(int i) {
    Haptics.tick();
    setState(() => _shopAt = i);
  }

  void _closeShop() => setState(() => _shopAt = null);

  /// "Shop the look" for the tapped piece: the fit's pieces with a cut-out,
  /// starting at that one.
  Widget? _shopSheet() {
    final at = _shopAt;
    if (at == null || at >= _spots.length) return null;
    final pieces = [
      for (final p in widget.outfit.pieces)
        if (p.image != null && p.image!.isNotEmpty) p,
    ];
    if (pieces.isEmpty) return null;
    return FitPiecesSheet(
      key: ValueKey('shop-${widget.outfit.id}'),
      pieces: pieces,
      initial: pieces.indexOf(_spots[at].piece),
      onClose: _closeShop,
    );
  }

  void _doubleTapLike() {
    final id = widget.outfit.id;
    if (!ref.read(fitMarksProvider).isLiked(id)) {
      toggleLikeWithToast(context, ref, id);
    }
    Haptics.thump();
    setState(() => _burst++);
  }

  void _toggle() {
    Haptics.tick();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final outfit = widget.outfit;
    final collage = outfit.isCollage;
    final pad = MediaQuery.paddingOf(context);
    // Clear of the status bar / cutout and the top bar. `pad.bottom` already
    // includes the floating nav's height (the shell adds it).
    final top = pad.top + 58.0;
    final fade = Motion.dur(context, Motion.content);
    // A collage's empty space is painted in the collage's own background, so
    // the flat-lay reads as filling the screen. Text over a pale one flips to
    // dark ink.
    final bg = _bg ?? AppColors.base;
    final light = collage && bg.computeLuminance() > 0.45;

    return SlideUpSheet(
      sheet: _shopSheet(),
      onClose: _closeShop,
      heightFactor: 0.6,
      bottomInset: pad.bottom,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: light
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.dark,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Color(0xFF0E1018),
                systemNavigationBarIconBrightness: Brightness.light,
              ),
        child: GestureDetector(
          onDoubleTap: _doubleTapLike,
          // Tapping the picture closes open details (and costs nothing otherwise).
          onTap: _expanded ? _toggle : null,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (collage)
                AnimatedContainer(
                  duration: Motion.dur(context, Motion.content),
                  color: bg,
                )
              else ...[
                FitHero(
                  ootdId: outfit.id,
                  radius: 28,
                  child: SizedBox.expand(
                    child: ColoredBox(
                      color: AppColors.base,
                      child: DripImage(
                        outfit.image,
                        alignment: Alignment.topCenter,
                      ),
                    ),
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
                // Bottom scrim: just enough for the identity line at rest ...
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 230,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xE60E1018), Color(0x000E1018)],
                          stops: [0.1, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                // ... and a deeper one while the details are open.
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _expanded ? 1 : 0,
                      duration: fade,
                      curve: Motion.out,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xF50E1018), Color(0x000E1018)],
                            stops: [0.35, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Column(
                children: [
                  SizedBox(height: top),
                  Expanded(
                    child: HintAnchor(
                      id: 'scroll.stage',
                      child: _Stage(
                        outfit: outfit,
                        expanded: _expanded,
                        ink: light ? AppColors.base : AppColors.cream,
                        shop: ShopTheLook(
                          spots: _spots,
                          onOpen: _expanded ? null : _openShop,
                          child: const SizedBox.shrink(),
                        ),
                        onBackground: (c) {
                          if (mounted && c != _bg) setState(() => _bg = c);
                        },
                      ),
                    ),
                  ),
                  _InfoPanel(
                    outfit: outfit,
                    expanded: _expanded,
                    onToggle: _toggle,
                    bottom: pad.bottom,
                    ink: light ? AppColors.base : AppColors.cream,
                  ),
                ],
              ),
              Center(child: LikeBurst(trigger: _burst, size: 110)),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────── stage

/// Everything between the top chrome and the info panel: the whole collage
/// (collages only) and the action rail on top. It is whatever room the panel leaves,
/// so opening the details shrinks the collage instead of covering it.
class _Stage extends StatelessWidget {
  const _Stage({
    required this.outfit,
    required this.expanded,
    required this.ink,
    required this.shop,
    required this.onBackground,
  });
  final Outfit outfit;
  final bool expanded;

  /// The rail's colour: cream, or dark ink over a pale flat-lay.
  final Color ink;

  /// Shop-the-look settings; the collage wraps itself in a copy of it.
  final ShopTheLook shop;
  final ValueChanged<Color> onBackground;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full width: collages (layout v3, 1080 × 1800) keep the lower-right
        // corner empty for the rail, which floats over it.
        if (outfit.isCollage)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: _FittedCollage(
                outfit: outfit,
                shop: shop,
                onBackground: onBackground,
              ),
            ),
          ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
            child: Align(
              alignment: Alignment.bottomRight,
              // Scales down rather than overflowing on a short screen.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: IgnorePointer(
                  ignoring: expanded,
                  child: AnimatedOpacity(
                    opacity: expanded ? 0 : 1,
                    duration: Motion.dur(context, Motion.quick),
                    child: HintAnchor(
                      id: 'scroll.rail',
                      child: _ActionRail(outfit: outfit, ink: ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A collage shown whole: as large as fits the room it is given, in its own
/// aspect ratio, never cropped. The aspect ratio and the background colour both
/// come from the decoded image; the colour goes up to the page so the space
/// around the collage matches it.
class _FittedCollage extends StatefulWidget {
  const _FittedCollage({
    required this.outfit,
    required this.shop,
    required this.onBackground,
  });
  final Outfit outfit;
  final ShopTheLook shop;
  final ValueChanged<Color> onBackground;

  @override
  State<_FittedCollage> createState() => _FittedCollageState();
}

class _FittedCollageState extends State<_FittedCollage> {
  double? _aspect;
  ImageStream? _stream;
  ui.Image? _sampled;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) {
      final a = info.image.width / info.image.height;
      if (mounted && a != _aspect) setState(() => _aspect = a);
      _sampleBackground(info.image);
    },
    // A broken image shows DripImage's own failure state, full size.
    onError: (_, _) {},
  );

  Future<void> _sampleBackground(ui.Image image) async {
    if (identical(image, _sampled)) return;
    _sampled = image;
    final c = await edgeColor(image);
    if (c != null && mounted) widget.onBackground(c);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_FittedCollage old) {
    super.didUpdateWidget(old);
    if (old.outfit.image != widget.outfit.image) _resolve();
  }

  void _resolve() {
    final next = dripImageProvider(widget.outfit.image)
        .resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final a = _aspect;
        final size = a == null
            ? c.biggest
            : applyBoxFit(
                BoxFit.contain,
                Size(a * 1000, 1000),
                c.biggest,
              ).destination;
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: ShopTheLook(
              spots: widget.shop.spots,
              onOpen: widget.shop.onOpen,
              child: FitHero(
                ootdId: widget.outfit.id,
                radius: 28,
                child: DripImage(widget.outfit.image, fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────── info panel

/// Instagram's reel caption block: who it's from, a one-line caption to tap,
/// and "Shop the look" with the pieces' faces and the price. Tapping the
/// caption opens the tags and the score in place.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.outfit,
    required this.expanded,
    required this.onToggle,
    required this.bottom,
    required this.ink,
  });
  final Outfit outfit;
  final bool expanded;
  final VoidCallback onToggle;
  final double bottom;

  /// Text colour over the page: cream, or dark ink over a pale collage.
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 10),
      child: AnimatedSize(
        duration: Motion.dur(context, Motion.content),
        curve: Motion.out,
        alignment: Alignment.bottomCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Curated by Drip (creator posts come after the beta).
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.base,
                    border: Border.all(color: p.accent, width: 1.5),
                  ),
                  child: Text('d.', style: AppText.fredoka(15)),
                ),
                const SizedBox(width: 10),
                Text(
                  '@drip',
                  style: AppText.manrope(
                    14,
                    weight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    outfit.isCollage ? 'Flat-lay' : 'Curated fit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.manrope(
                      12,
                      weight: FontWeight.w500,
                      color: ink.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _FollowChip(
                  ink: ink,
                  onTap: () => showAfterBeta(context, 'Following creators'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: expanded
                  ? 'Hide details'
                  : 'Show details: ${outfit.title}',
              excludeSemantics: true,
              onTap: onToggle,
              child: GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: expanded
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.base.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: _Details(outfit: outfit),
                      )
                    : _Caption(title: outfit.title, ink: ink),
              ),
            ),
            if (outfit.pieces.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ShopStrip(outfit: outfit),
            ],
          ],
        ),
      ),
    );
  }
}

/// The resting caption: the fit's name on one line and a quiet "more".
class _Caption extends StatelessWidget {
  const _Caption({required this.title, required this.ink});
  final String title;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.manrope(14, weight: FontWeight.w600, color: ink),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'more',
            style: AppText.manrope(
              13,
              weight: FontWeight.w600,
              color: ink.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything about the post, shown on request.
class _Details extends StatelessWidget {
  const _Details({required this.outfit});
  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final story = outfit.colourStory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                outfit.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.manrope(
                  17,
                  weight: FontWeight.w800,
                  lineHeight: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'less',
                style: AppText.manrope(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        if (story != null && story.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            story,
            style: AppText.manrope(
              13,
              color: const Color(0xFFE6DED0),
              lineHeight: 18,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MetaChip(outfit.isCollage ? 'COLLAGE' : 'ON BODY', filled: true),
            for (final t in outfit.tags.take(3)) _MetaChip(t.toUpperCase()),
            _MetaChip('✦ DRIP ${outfit.rate}', color: p.accent),
          ],
        ),
      ],
    );
  }
}

/// Instagram's outlined "Follow" on a reel.
class _FollowChip extends StatelessWidget {
  const _FollowChip({required this.ink, required this.onTap});
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      scale: 0.94,
      semanticLabel: 'Follow',
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: ink.withValues(alpha: 0.6)),
        ),
        child: Text(
          'Follow',
          style: AppText.manrope(12, weight: FontWeight.w700, color: ink),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label, {this.filled = false, this.color});
  final String label;
  final bool filled;

  /// Text colour; cream when null.
  final Color? color;

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
          10,
          color: color ?? AppColors.cream,
          weight: filled || color != null ? FontWeight.w500 : FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// "Shop the look": the pieces' cut-outs, the total and the budget band in
/// colour. Tapping opens the pieces over the feed; each links to its store.
class _ShopStrip extends ConsumerWidget {
  const _ShopStrip({required this.outfit});
  final Outfit outfit;

  static const _thumb = 34.0;
  static const _inBudget = Color(0xFF7BE0A0);
  static const _overBudget = Color(0xFFFFB27A);

  /// The server's budget band, said plainly, so a jump in price as the feed
  /// moves past the fits in budget doesn't come as a surprise.
  static (String, Color)? _band(String? band) => switch (band) {
    'in' => ('in budget', _inBudget),
    'over' => ('over budget', _overBudget),
    _ => null,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = outfit.price;
    final n = outfit.pieces.length;
    final noun = n == 1 ? 'PIECE' : 'PIECES';
    final faces = [
      for (final p in outfit.pieces)
        if (p.image != null && p.image!.isNotEmpty) p.image!,
    ].take(3).toList();
    final band = _band(outfit.budgetBand);
    return Tap(
      onTap: () {
        ref.read(feedProvider.notifier).signal(outfit.id, 'open');
        showShopSheet(
          context,
          outfit,
          onFullBreakdown: () => context.push('/outfit/${outfit.id}'),
        );
      },
      semanticLabel: 'Shop the look: ${outfit.title}',
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.base.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            if (faces.isNotEmpty) ...[
              SizedBox(
                width: _thumb + (_thumb - 10) * (faces.length - 1),
                height: _thumb,
                child: Stack(
                  children: [
                    for (var i = faces.length - 1; i >= 0; i--)
                      Positioned(
                        left: i * (_thumb - 10),
                        child: Container(
                          width: _thumb,
                          height: _thumb,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8DF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.base,
                              width: 1.5,
                            ),
                          ),
                          child: DripImage(
                            faces[i],
                            fit: BoxFit.contain,
                            logicalWidth: _thumb,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHOP THE LOOK · $n $noun',
                    style: AppText.mono(
                      10,
                      color: AppColors.muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      text: total > 0
                          ? '${formatPrice(total)} total'
                          : 'See the pieces',
                      children: [
                        if (total > 0 && band != null)
                          TextSpan(
                            text: ' · ${band.$1}',
                            style: AppText.manrope(
                              13,
                              weight: FontWeight.w700,
                              color: band.$2,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.manrope(13, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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

/// Like, save, send, report: Instagram's bare icons, no discs. A soft shadow
/// keeps them legible on photos, and over a pale flat-lay they turn to dark
/// ink. No blur, so nothing is redrawn while the page moves. There are no
/// comments: Drip's conversations happen where people already talk, so
/// "Send" is the loudest thing on the rail.
class _ActionRail extends ConsumerWidget {
  const _ActionRail({required this.outfit, required this.ink});
  final Outfit outfit;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marks = ref.watch(fitMarksProvider);
    final liked = marks.isLiked(outfit.id);
    final saved = marks.isSaved(outfit.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailButton(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? AppColors.red : ink,
          ink: ink,
          size: 30,
          semantic: liked ? 'Unlike' : 'Like',
          onTap: () {
            Haptics.commit();
            toggleLikeWithToast(context, ref, outfit.id);
          },
        ),
        _RailButton(
          icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: saved ? context.palette.accent : ink,
          ink: ink,
          semantic: saved ? 'Remove from saved' : 'Save',
          onTap: () {
            Haptics.commit();
            toggleSaveWithToast(context, ref, outfit.id);
          },
        ),
        _SendButton(ink: ink, onTap: () => showShareFit(context, outfit)),
        _RailButton(
          icon: Icons.outlined_flag_rounded,
          color: ink.withValues(alpha: 0.85),
          ink: ink,
          size: 24,
          semantic: 'Report a bug',
          onTap: () =>
              showReportBug(context, screen: 'scroll', fitId: outfit.id),
        ),
      ],
    );
  }
}

/// The rail's one filled button: a red disc that opens "Send this fit".
class _SendButton extends StatelessWidget {
  const _SendButton({required this.ink, required this.onTap});
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Tap(
        onTap: onTap,
        scale: 0.88,
        semanticLabel: 'Send',
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_outlined,
                  size: 23,
                  color: inkOn(accent),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Send',
                style: AppText.manrope(12, weight: FontWeight.w800, color: ink)
                    .copyWith(
                      shadows: ink.computeLuminance() > 0.5
                          ? const [
                              Shadow(color: Color(0x8C000000), blurRadius: 8),
                            ]
                          : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.semantic,
    required this.onTap,
    required this.color,
    required this.ink,
    this.size = 28,
  });

  final IconData icon;
  final Color color;

  /// The rail's base colour: a shadow only behind light icons.
  final Color ink;
  final double size;
  final String semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = ink.computeLuminance() > 0.5;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Tap(
        onTap: onTap,
        scale: 0.86,
        semanticLabel: semantic,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedSwitcher(
              duration: Motion.quick,
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: size,
                color: color,
                shadows: light
                    ? const [Shadow(color: Color(0x8C000000), blurRadius: 10)]
                    : null,
              ),
            ),
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
            bottom: bottom + 8,
            right: 84,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Skeleton(width: 34, height: 34, circle: true),
                    SizedBox(width: 10),
                    Skeleton(width: 90, height: 14, radius: 7),
                  ],
                ),
                SizedBox(height: 12),
                Skeleton(width: 200, height: 12, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
