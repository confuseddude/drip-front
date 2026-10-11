import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Marks a widget a hint can point at. Several may share an [id] (one per
/// page of the Scroll, say); the hint uses the one most on screen.
class HintAnchor extends StatefulWidget {
  const HintAnchor({super.key, required this.id, required this.child});
  final String id;
  final Widget child;

  /// Live anchors by id.
  static final _live = <String, Set<GlobalKey>>{};

  /// The rect (in [ancestor]'s coordinates) of the anchor [id] most visible
  /// inside [bounds], and how much of it is visible (0–1). Null when none is
  /// laid out there.
  static (Rect, double)? find(String id, RenderBox ancestor, Rect bounds) {
    (Rect, double)? best;
    var bestArea = 0.0;
    for (final key in _live[id] ?? const <GlobalKey>{}) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final rect =
          box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
      final seen = rect.intersect(bounds);
      final area = seen.isEmpty ? 0.0 : seen.width * seen.height;
      final whole = rect.width * rect.height;
      if (area > bestArea && whole > 0) {
        bestArea = area;
        best = (rect, area / whole);
      }
    }
    return best;
  }

  @override
  State<HintAnchor> createState() => _HintAnchorState();
}

class _HintAnchorState extends State<HintAnchor> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    HintAnchor._live.putIfAbsent(widget.id, () => {}).add(_key);
  }

  @override
  void didUpdateWidget(HintAnchor old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      HintAnchor._live[old.id]?.remove(_key);
      HintAnchor._live.putIfAbsent(widget.id, () => {}).add(_key);
    }
  }

  @override
  void dispose() {
    HintAnchor._live[widget.id]?.remove(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// One just-in-time tip: a line about [anchor], shown the first time the
/// user is on [route] with it on screen.
class Hint {
  const Hint(
    this.id, {
    required this.route,
    required this.anchor,
    required this.text,
  });
  final String id;

  /// The shell location it belongs to (exact path).
  final String route;

  /// What it points at ([HintAnchor.id]).
  final String anchor;
  final String text;
}

/// The tips, by screen, most useful first. Only what people can't guess
/// from apps they already use (a feed scrolls, a heart likes, a tab bar
/// switches screens): what's particular to Drip. A screen shows at most one
/// per visit, so a screen with several spreads them over the first visits.
const hints = [
  Hint(
    'home.camera',
    route: '/home',
    anchor: 'home.camera',
    text:
        'Snap a piece you own. Drip cuts it out and files it in your wardrobe.',
  ),
  Hint(
    'home.tools',
    route: '/home',
    anchor: 'home.tools',
    text:
        'Your tools: a guided selfie, your palette, your shop list and a '
        '10-tap quiz that tunes your feed.',
  ),
  Hint(
    'nav.swipe',
    route: '/home',
    anchor: 'nav',
    text: 'Swipe sideways anywhere to hop between tabs.',
  ),
  Hint(
    'scroll.shop',
    route: '/scroll',
    anchor: 'scroll.stage',
    text: 'Tap any piece in a fit to see its price and where to buy it.',
  ),
  Hint(
    'scroll.rail',
    route: '/scroll',
    anchor: 'scroll.rail',
    text: 'Something look off? The bug button sends it straight to us.',
  ),
  Hint(
    'studio.new',
    route: '/studio',
    anchor: 'studio.new',
    text: 'Build a fit on a blank canvas, or ask Taylor to style one for you.',
  ),
  Hint(
    'studio.canvas',
    route: '/studio/builder',
    anchor: 'studio.canvas',
    text: 'Tap a + to add pieces. Tap a piece to resize, swap or remove it.',
  ),
  Hint(
    'wardrobe.add',
    route: '/wardrobe',
    anchor: 'wardrobe.add',
    text: 'Add photos of what you own. They show up in the Studio and with Taylor.',
  ),
  Hint(
    'me.style',
    route: '/me',
    anchor: 'me.style',
    text: 'Your style picks live here. Change them any time.',
  ),
];

/// Whether tips show at all (off in tests, which turn them on by hand).
final hintsEnabledProvider = Provider<bool>((ref) => true);

/// The tip on screen, or null. Each is shown once: dismissing it (or
/// leaving the screen) records it as seen on the device.
class HintsController extends Notifier<Hint?> {
  @override
  Hint? build() => null;

  bool isSeen(Hint hint) =>
      ref.read(localStoreProvider).hintsSeen.contains(hint.id);

  void show(Hint hint) => state = hint;

  void dismiss() {
    final hint = state;
    if (hint == null) return;
    state = null;
    final store = ref.read(localStoreProvider);
    store.setHintsSeen({...store.hintsSeen, hint.id});
  }

  /// Settings → Show tips again: every tip comes back, one at a time.
  Future<void> reset() async {
    state = null;
    await ref.read(localStoreProvider).setHintsSeen(const {});
  }
}

final hintsProvider = NotifierProvider<HintsController, Hint?>(
  HintsController.new,
);
