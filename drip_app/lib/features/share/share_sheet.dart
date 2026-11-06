import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/drip_image.dart';
import '../../core/widgets/image_tint.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import '../../data/models/outfit.dart';
import 'share_link.dart';

/// "Send this fit": what the link will look like, then one tap to WhatsApp,
/// a story card for Instagram or Snapchat, a copied link, or any other app.
///
/// Sharing is how Drip grows, so this is never more than two taps from a
/// fit, and nothing here asks a question first.
Future<void> showShareFit(BuildContext context, Outfit outfit) {
  Haptics.tick();
  return showDripSheet<void>(
    context,
    builder: (_) => ShareFitSheet(outfit: outfit),
  );
}

class ShareFitSheet extends StatefulWidget {
  const ShareFitSheet({super.key, required this.outfit});
  final Outfit outfit;

  @override
  State<ShareFitSheet> createState() => _ShareFitSheetState();
}

class _ShareFitSheetState extends State<ShareFitSheet> {
  bool _story = false;
  bool _busy = false;
  final _card = GlobalKey();

  Outfit get _fit => widget.outfit;
  String get _url => fitShareUrl(_fit);
  String get _text => fitShareText(_fit, url: _url);

  void _done(String message) {
    if (!mounted) return;
    Navigator.of(context).pop();
    showDripToast(context, message);
  }

  Future<void> _whatsApp() async {
    Haptics.commit();
    final ok = await launchUrl(
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_text)}'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) await _system();
  }

  Future<void> _copy() async {
    Haptics.commit();
    await Clipboard.setData(ClipboardData(text: _url));
    _done('Link copied');
  }

  Future<void> _system() async {
    Haptics.commit();
    final origin = _origin();
    await SharePlus.instance.share(
      ShareParams(
        text: _text,
        subject: '${_fit.title} on Drip',
        sharePositionOrigin: origin,
      ),
    );
  }

  /// The story card as a 1080×1920 picture, shared with the link as its
  /// caption: Instagram and Snapchat pick it up from the share sheet.
  Future<void> _storyCard() async {
    if (_busy) return;
    setState(() => _busy = true);
    Haptics.commit();
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final size = boundary.size;
      final image = await boundary.toImage(pixelRatio: 1080 / size.width);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw const FileSystemException('no image');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/drip-${shareId(_fit.id)}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: _text,
          sharePositionOrigin: _origin(),
        ),
      );
    } catch (_) {
      // A card that can't be drawn still leaves the link.
      await _system();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Rect? _origin() {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text('SEND THIS FIT', style: AppText.display(17)),
              ),
              Text('ONE TAP', style: AppText.mono(10, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: Motion.dur(context, Motion.quick),
            child: _story
                ? _StoryPreview(
                    key: const ValueKey('story'),
                    outfit: _fit,
                    card: _card,
                  )
                : _LinkPreview(
                    key: const ValueKey('link'),
                    outfit: _fit,
                    url: _url,
                  ),
          ),
          const SizedBox(height: 12),
          _Toggle(
            story: _story,
            onChanged: (v) {
              Haptics.tick();
              setState(() => _story = v);
            },
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Target(
                label: 'WhatsApp',
                bg: const Color(0xFF25D366),
                icon: Icons.chat_rounded,
                onTap: _whatsApp,
              ),
              _Target(
                label: 'Stories',
                bg: const Color(0xFFE1306C),
                icon: Icons.amp_stories_rounded,
                busy: _busy,
                onTap: () {
                  if (!_story) setState(() => _story = true);
                  // Let the card paint before it's captured.
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _storyCard(),
                  );
                },
              ),
              _Target(
                label: 'Copy link',
                bg: AppColors.elevated,
                icon: Icons.link_rounded,
                onTap: _copy,
              ),
              _Target(
                label: 'More',
                bg: AppColors.elevated,
                icon: Icons.more_horiz_rounded,
                onTap: _system,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'The link opens the fit in Drip, or its page with every piece '
            'for friends without the app.',
            style: AppText.manrope(12, color: AppColors.muted, lineHeight: 17),
          ),
        ],
      ),
    );
  }
}

/// How the link unfurls in a chat: the fit on its own colour, the Drip mark,
/// the name, pieces and price, and the address.
class _LinkPreview extends StatelessWidget {
  const _LinkPreview({super.key, required this.outfit, required this.url});
  final Outfit outfit;
  final String url;

  @override
  Widget build(BuildContext context) {
    final n = outfit.pieces.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: AppColors.base,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImageTint(
              image: outfit.image,
              fallback: AppColors.cream,
              builder: (context, tint) => Container(
                height: 150,
                color: tint,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: DripImage(
                          outfit.image,
                          fit: BoxFit.contain,
                          backdrop: false,
                        ),
                      ),
                    ),
                    const Positioned(left: 10, top: 10, child: _Mark()),
                    if (n > 0 || outfit.price > 0)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: _Chip(
                          [
                            if (n > 0) '$n ${n == 1 ? 'piece' : 'pieces'}',
                            if (outfit.price > 0) formatPrice(outfit.price),
                          ].join(' · '),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: context.palette.accent, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${outfit.title} on Drip',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.manrope(14, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Shop every piece, or make it your own.',
                    style: AppText.manrope(12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url.replaceFirst(RegExp(r'^https?://'), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mono(10, color: AppColors.cyan),
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

/// The story card, drawn here at 9:16 and captured at 1080×1920.
class _StoryPreview extends StatelessWidget {
  const _StoryPreview({super.key, required this.outfit, required this.card});
  final Outfit outfit;
  final GlobalKey card;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RepaintBoundary(
          key: card,
          child: ImageTint(
            image: outfit.image,
            fallback: AppColors.cream,
            builder: (context, tint) {
              final ink = inkOn(tint);
              return Container(
                width: 135,
                height: 240,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DripWordmark(
                      height: 16,
                      variant: WordmarkVariant.mono,
                      color: ink,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: DripImage(
                        outfit.image,
                        fit: BoxFit.contain,
                        backdrop: false,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      outfit.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(10, color: ink, lineHeight: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Shop it on Drip',
                        style: AppText.manrope(
                          8,
                          weight: FontWeight.w800,
                          color: tint,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A story-sized card',
                style: AppText.manrope(14, weight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'For Instagram and Snapchat stories. Add the link sticker '
                'there, and the link is already copied in the caption.',
                style: AppText.manrope(
                  12.5,
                  color: AppColors.muted,
                  lineHeight: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.base,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: const DripWordmark(height: 18),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.base,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(label, style: AppText.manrope(12, weight: FontWeight.w800)),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.story, required this.onChanged});
  final bool story;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool on, bool value) => Expanded(
      child: Tap(
        onTap: () => onChanged(value),
        semanticLabel: label,
        scale: 0.98,
        child: AnimatedContainer(
          duration: Motion.dur(context, Motion.quick),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.cream : AppColors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppText.manrope(
              12.5,
              weight: FontWeight.w800,
              color: on ? AppColors.base : AppColors.muted,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.base,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab('Link with preview', !story, false),
          const SizedBox(width: 4),
          tab('Story card', story, true),
        ],
      ),
    );
  }
}

class _Target extends StatelessWidget {
  const _Target({
    required this.label,
    required this.bg,
    required this.icon,
    required this.onTap,
    this.busy = false,
  });
  final String label;
  final Color bg;
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ink = inkOn(bg);
    return Tap(
      onTap: busy ? null : onTap,
      semanticLabel: label,
      scale: 0.92,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(17),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ink,
                      ),
                    )
                  : Icon(icon, size: 26, color: ink),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              style: AppText.manrope(11.5, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
