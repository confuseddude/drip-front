import 'package:flutter/widgets.dart';

import '../motion.dart';
import '../utils/image_color.dart';
import 'drip_image.dart';

/// Builds with the background colour of [image] (a flat-lay's own ground),
/// so a card can wear the fit it shows. Uses [fallback] until the picture has
/// decoded, and for pictures with no solid ground (cut-outs, photos with a
/// busy edge). Colours are remembered per image for the session.
class ImageTint extends StatefulWidget {
  const ImageTint({
    super.key,
    required this.image,
    required this.fallback,
    required this.builder,
  });

  final String image;
  final Color fallback;
  final Widget Function(BuildContext context, Color tint) builder;

  static final _known = <String, Color?>{};

  @override
  State<ImageTint> createState() => _ImageTintState();
}

class _ImageTintState extends State<ImageTint> {
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener((
    info,
    _,
  ) async {
    final source = widget.image;
    if (ImageTint._known.containsKey(source)) return;
    final c = await edgeColor(info.image);
    ImageTint._known[source] = c;
    if (mounted && source == widget.image) setState(() {});
  }, onError: (_, _) {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ImageTint old) {
    super.didUpdateWidget(old);
    if (old.image != widget.image) _resolve();
  }

  void _resolve() {
    if (widget.image.isEmpty || ImageTint._known.containsKey(widget.image)) {
      return;
    }
    final next = dripImageProvider(widget.image)
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
    final tint = ImageTint._known[widget.image] ?? widget.fallback;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: tint),
      duration: Motion.dur(context, Motion.content),
      builder: (context, c, _) => widget.builder(context, c ?? tint),
    );
  }
}

/// Ink that reads on [ground]: near-black on light grounds, white on dark.
Color inkOn(Color ground) => ground.computeLuminance() > 0.4
    ? const Color(0xFF15170E)
    : const Color(0xFFFFFFFF);
