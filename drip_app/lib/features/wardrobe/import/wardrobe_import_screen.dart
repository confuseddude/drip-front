import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/overlays.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/tap.dart';
import '../../onboarding/onboarding_widgets.dart' show Enter;
import 'import_art.dart';
import 'import_controller.dart';
import 'photo_check.dart';

/// "Welcome to your wardrobe": the user shares outfit photos and Drip builds
/// the wardrobe they already own. One screen walks the whole way: what
/// photos work best → pick (the system picker, up to 50) → the phone's
/// checks → upload → "we're on it, keep exploring" → done. No review step:
/// the pieces land in the wardrobe by themselves, and a bad cut-out can be
/// reported from its page.
class WardrobeImportScreen extends ConsumerWidget {
  const WardrobeImportScreen({super.key});

  void _close(BuildContext context) =>
      context.canPop() ? context.pop() : context.go('/wardrobe');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(wardrobeImportProvider);
    final ctrl = ref.read(wardrobeImportProvider.notifier);
    ref.listen(wardrobeImportProvider.select((r) => r.error), (_, error) {
      if (error != null && run.phase == ImportPhase.idle) {
        showDripToast(context, error);
      }
    });

    final Widget body = switch (run.phase) {
      ImportPhase.idle => _Welcome(onPick: ctrl.pick),
      ImportPhase.checking || ImportPhase.ready => _Checking(
        run: run,
        onSend: () => ctrl.start(),
        onRepick: ctrl.pick,
      ),
      ImportPhase.uploading => _Uploading(run: run),
      ImportPhase.processing => _Working(run: run),
      ImportPhase.done => _Finished(run: run, onAgain: ctrl.dismiss),
      ImportPhase.failed || ImportPhase.unavailable => _Problem(
        run: run,
        onRetry: () => ctrl.start(),
        onPreview: () => ctrl.start(preview: true),
        onReset: ctrl.dismiss,
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 20, 0),
              child: Row(
                children: [
                  Tap(
                    semanticLabel: 'Close',
                    scale: 0.9,
                    onTap: () => _close(context),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (run.preview)
                    Text(
                      'PREVIEW · NOTHING IS ADDED',
                      style: AppText.mono(9, color: AppColors.muted),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Motion.dur(context, Motion.content),
                switchInCurve: Motion.out,
                child: KeyedSubtree(
                  key: ValueKey(_stage(run.phase)),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Checking and ready share a page (the grid just settles).
  static String _stage(ImportPhase p) => switch (p) {
    ImportPhase.checking || ImportPhase.ready => 'check',
    ImportPhase.failed || ImportPhase.unavailable => 'problem',
    _ => p.name,
  };
}

/// A scrolling page with its actions pinned at the bottom.
class _Page extends StatelessWidget {
  const _Page({required this.content, required this.actions});
  final List<Widget> content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: content,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottom > 0 ? 8 : 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: actions),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.kicker, required this.title, this.body});
  final String kicker;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker,
          style: AppText.mono(
            10,
            color: context.palette.accent,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: AppText.display(26, lineHeight: 31)),
        if (body != null) ...[
          const SizedBox(height: 10),
          Text(
            body!,
            style: AppText.manrope(14, color: AppColors.muted, lineHeight: 20),
          ),
        ],
      ],
    );
  }
}

/// A quiet text button under the main one.
class _Secondary extends StatelessWidget {
  const _Secondary(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    semanticLabel: label,
    child: SizedBox(
      height: 44,
      child: Center(
        child: Text(label, style: AppText.mono(11, color: AppColors.cream)),
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar(this.value);
  final double value;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.deep)),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0.0, 1.0)),
              duration: Motion.dur(context, Motion.content),
              curve: Motion.out,
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: ColoredBox(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Welcome: what works best.
// ---------------------------------------------------------------------------

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});
  final VoidCallback onPick;

  static const _tips = [
    (
      TipArt.solo,
      'JUST YOU',
      'One person per photo. Group shots arrive in the next update.',
    ),
    (
      TipArt.mirror,
      'MIRROR SELFIES',
      'Mirror or full-body shots, head to toe, so we catch your shoes too.',
    ),
    (
      TipArt.light,
      'GOOD LIGHT',
      'Daylight or a bright room. Dark photos lose the details.',
    ),
    (
      TipArt.loved,
      'FITS YOU LOVE',
      'The ones where you know you look good. We style around those.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return _Page(
      content: [
        const _Heading(
          kicker: 'WARDROBE',
          title: 'WELCOME TO YOUR WARDROBE',
          body:
              'Share photos of your outfits and we\'ll handle the rest: every '
              'piece cut out, sorted and ready to style. The clothes you '
              'already own, all in one place.',
        ),
        const SizedBox(height: 26),
        Text(
          'WHAT WORKS BEST',
          style: AppText.mono(10, color: AppColors.muted, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        for (var row = 0; row < _tips.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = row; i < row + 2; i++) ...[
                  if (i > row) const SizedBox(width: 10),
                  Expanded(
                    child: Enter(
                      delay: Duration(milliseconds: 60 + i * 70),
                      dy: 12,
                      duration: const Duration(milliseconds: 420),
                      child: _TipCard(
                        art: _tips[i].$1,
                        title: _tips[i].$2,
                        text: _tips[i].$3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Enter(
          delay: const Duration(milliseconds: 360),
          dy: 12,
          duration: const Duration(milliseconds: 420),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.elevated),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: TipDrawing(
                    TipArt.group,
                    ink: AppColors.muted,
                    accent: AppColors.red,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Skip group shots, screenshots, flat-lays and heavy '
                    'filters. We\'ll set those aside for you anyway.',
                    style: AppText.manrope(
                      12,
                      color: AppColors.muted,
                      lineHeight: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔒', style: AppText.inter(13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          'We only look at your clothes. Faces and '
                          'backgrounds are thrown away, and your photos are '
                          'deleted from our servers once your pieces are cut '
                          'out. ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Tap(
                        onTap: () => context.push('/privacy'),
                        semanticLabel: 'Privacy policy',
                        child: Text(
                          'Privacy policy',
                          style: AppText.manrope(
                            12,
                            color: accent,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                style: AppText.manrope(
                  12,
                  color: AppColors.dim,
                  lineHeight: 17,
                ),
              ),
            ),
          ],
        ),
      ],
      actions: [
        AppButton(
          label: 'CHOOSE UP TO 50 PHOTOS',
          height: 50,
          onPressed: onPick,
        ),
        _Secondary(
          'OR SNAP A SINGLE PIECE',
          () => context.pushReplacement('/wardrobe/capture'),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.art, required this.title, required this.text});
  final TipArt art;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.elevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TipDrawing(
            art,
            ink: AppColors.cream,
            accent: context.palette.accent,
            height: 72,
          ),
          const SizedBox(height: 12),
          Text(title, style: AppText.mono(10, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            text,
            style: AppText.manrope(12, color: AppColors.muted, lineHeight: 16),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. The phone's checks, photo by photo.
// ---------------------------------------------------------------------------

class _Checking extends StatelessWidget {
  const _Checking({
    required this.run,
    required this.onSend,
    required this.onRepick,
  });
  final ImportRun run;
  final VoidCallback onSend;
  final VoidCallback onRepick;

  @override
  Widget build(BuildContext context) {
    final checking = run.phase == ImportPhase.checking;
    final kept = run.kept.length;
    final total = run.photos.length;
    final skipped = run.skipped;
    final groups = skipped.any((s) => s.$1 == PhotoVerdict.group);

    final (title, body) = checking
        ? (
            'LOOKING AT YOUR PHOTOS',
            'Setting aside group shots, repeats and anything we can\'t '
                'read. This stays on your phone.',
          )
        : kept == 0
        ? (
            'NONE OF THESE WILL WORK',
            'Try mirror selfies or full-body shots of just you, in good '
                'light.',
          )
        : (
            kept == total ? 'ALL SET' : 'LOOKING GOOD',
            '$kept photo${kept == 1 ? '' : 's'} ready. We\'ll find every '
                'piece in them and fold the repeats together.',
          );

    return _Page(
      content: [
        _Heading(
          kicker: checking
              ? 'CHECKING ${run.checked} OF $total'
              : '$kept OF $total READY',
          title: title,
          body: body,
        ),
        if (!checking && skipped.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (verdict, n) in skipped)
                _Chip('$n × ${verdict.reason.toLowerCase()}'),
            ],
          ),
          if (groups) ...[
            const SizedBox(height: 10),
            Text(
              'Group photos are coming in the next update.',
              style: AppText.manrope(12, color: AppColors.dim),
            ),
          ],
        ],
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final p in run.photos) _Thumb(photo: p)],
        ),
      ],
      actions: [
        AppButton(
          label: kept == 0
              ? 'BUILD MY WARDROBE'
              : 'BUILD MY WARDROBE · $kept PHOTO${kept == 1 ? '' : 'S'}',
          height: 50,
          onPressed: !checking && kept > 0 ? onSend : null,
        ),
        _Secondary('PICK DIFFERENT PHOTOS', onRepick),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.elevated),
    ),
    child: Text(label, style: AppText.manrope(12, color: AppColors.cream)),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo});
  final PickedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final v = photo.verdict;
    final pending = v == PhotoVerdict.pending;
    final skipped = !pending && !v.kept;
    final quick = Motion.dur(context, Motion.quick);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(photo.path),
            fit: BoxFit.cover,
            cacheWidth: 240,
            errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.deep),
          ),
          AnimatedOpacity(
            duration: quick,
            opacity: pending || skipped ? 1 : 0,
            child: ColoredBox(
              color: AppColors.base.withValues(alpha: skipped ? 0.72 : 0.45),
            ),
          ),
          if (pending)
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cream,
                ),
              ),
            ),
          if (skipped)
            Padding(
              padding: const EdgeInsets.all(5),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  v.reason.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppText.mono(7.5, color: AppColors.cream),
                ),
              ),
            ),
          Positioned(
            right: 5,
            top: 5,
            child: AnimatedScale(
              duration: quick,
              curve: Motion.out,
              scale: v.kept ? 1 : 0,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: context.palette.onAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Uploading.
// ---------------------------------------------------------------------------

class _Uploading extends StatelessWidget {
  const _Uploading({required this.run});
  final ImportRun run;

  @override
  Widget build(BuildContext context) {
    final total = run.kept.length;
    return _Page(
      content: [
        _Heading(
          kicker: 'SENDING ${run.uploaded} OF $total',
          title: 'SENDING YOUR PHOTOS',
          body:
              'This part needs a connection. You can switch apps, it keeps '
              'going in the background.',
        ),
        const SizedBox(height: 24),
        _Bar(total == 0 ? 0 : run.uploaded / total),
        const SizedBox(height: 24),
        const SizedBox(height: 180, child: LoadingState(label: 'UPLOADING...')),
      ],
      actions: [
        AppButton(
          label: 'KEEP EXPLORING',
          height: 50,
          style: AppButtonStyle.subtle,
          onPressed: () => context.go('/home'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. The hand-off: it takes a while, go and explore.
// ---------------------------------------------------------------------------

class _Working extends StatelessWidget {
  const _Working({required this.run});
  final ImportRun run;

  @override
  Widget build(BuildContext context) {
    final s = run.server;
    final line = s == null
        ? 'GETTING STARTED'
        : s.grouping
        ? 'SORTING OUT REPEATS'
        : 'CUT OUT ${s.photosDone} OF ${s.photosTotal} PHOTOS';
    return _Page(
      content: [
        const _Heading(
          kicker: 'WE\'RE ON IT',
          title: 'THIS TAKES A FEW MINUTES',
          body:
              'Cutting out every piece takes a little while. Keep exploring '
              'Drip, or switch to another app. We\'ll send you a notification '
              'when your wardrobe is ready, and your pieces will start '
              'showing up in your feed.',
        ),
        const SizedBox(height: 24),
        Text(line, style: AppText.mono(10, color: AppColors.muted)),
        const SizedBox(height: 8),
        _Bar(s?.progress ?? 0),
        const SizedBox(height: 24),
        const SizedBox(
          height: 180,
          child: LoadingState(label: 'BUILDING YOUR WARDROBE...'),
        ),
      ],
      actions: [
        AppButton(
          label: 'KEEP EXPLORING',
          height: 50,
          onPressed: () => context.go('/home'),
        ),
        _Secondary('SEE MY WARDROBE', () => context.go('/wardrobe')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Done.
// ---------------------------------------------------------------------------

class _Finished extends StatelessWidget {
  const _Finished({required this.run, required this.onAgain});
  final ImportRun run;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final s = run.server;
    final stats = [
      ('${s?.piecesAdded ?? 0}', 'NEW PIECES'),
      ('${s?.duplicatesMerged ?? 0}', 'REPEATS FOLDED'),
      if ((s?.alreadyOwned ?? 0) > 0) ('${s!.alreadyOwned}', 'ALREADY OWNED'),
    ];
    return _Page(
      content: [
        _Heading(
          kicker: 'DONE',
          title: 'YOUR WARDROBE IS READY',
          body: s == null ? null : importSummary(s),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            for (final (i, (n, label)) in stats.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.elevated),
                  ),
                  child: Column(
                    children: [
                      Text(
                        n,
                        style: AppText.display(
                          28,
                          color: i == 0
                              ? context.palette.accent
                              : AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppText.mono(8.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Something cut out wrong? Open the piece and tap "Report this '
          'cut-out". We\'ll fix it.',
          style: AppText.manrope(12, color: AppColors.dim, lineHeight: 17),
        ),
      ],
      actions: [
        AppButton(
          label: 'SEE MY WARDROBE',
          height: 50,
          onPressed: () {
            onAgain();
            context.go('/wardrobe');
          },
        ),
        _Secondary('ADD MORE PHOTOS', onAgain),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Failed, or the server isn't ready for imports yet.
// ---------------------------------------------------------------------------

class _Problem extends StatelessWidget {
  const _Problem({
    required this.run,
    required this.onRetry,
    required this.onPreview,
    required this.onReset,
  });
  final ImportRun run;
  final VoidCallback onRetry;
  final VoidCallback onPreview;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final unavailable = run.phase == ImportPhase.unavailable;
    final canRetry = run.kept.isNotEmpty;
    return _Page(
      content: [
        _Heading(
          kicker: unavailable ? 'ALMOST THERE' : 'THAT DIDN\'T WORK',
          title: unavailable ? 'SWITCHING THIS ON' : 'WE COULDN\'T BUILD IT',
          body: unavailable
              ? 'Your photos passed the checks. The part of Drip that cuts '
                    'clothes out of photos goes live with our next server '
                    'update. Try again soon.'
              : run.error ?? 'Something went wrong. Try again.',
        ),
      ],
      actions: [
        if (unavailable && kDebugMode)
          AppButton(label: 'PREVIEW THE REST', height: 50, onPressed: onPreview)
        else if (!unavailable && canRetry)
          AppButton(label: 'TRY AGAIN', height: 50, onPressed: onRetry),
        _Secondary(
          unavailable ? 'BACK TO WARDROBE' : 'START OVER',
          unavailable
              ? () {
                  onReset();
                  context.go('/wardrobe');
                }
              : onReset,
        ),
      ],
    );
  }
}
