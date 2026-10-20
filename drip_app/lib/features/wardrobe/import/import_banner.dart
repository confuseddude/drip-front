import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tap.dart';
import 'import_controller.dart';

/// The gallery import at a glance, on top of the Wardrobe: sending, cutting
/// out, done, or stuck. Tapping it opens the import screen. Nothing shows
/// when there's no import.
class ImportBanner extends ConsumerWidget {
  const ImportBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(wardrobeImportProvider);
    final accent = context.palette.accent;
    final s = run.server;

    final (
      String title,
      String? line,
      double? progress,
      bool alert,
    ) = switch (run.phase) {
      ImportPhase.idle || ImportPhase.unavailable => ('', null, null, false),
      ImportPhase.checking => (
        'CHECKING YOUR PHOTOS',
        '${run.checked} of ${run.photos.length}',
        run.photos.isEmpty ? 0.0 : run.checked / run.photos.length,
        false,
      ),
      ImportPhase.ready => (
        '${run.kept.length} PHOTOS READY TO SEND',
        'Tap to build your wardrobe',
        null,
        false,
      ),
      ImportPhase.uploading => (
        'SENDING YOUR PHOTOS',
        '${run.uploaded} of ${run.kept.length}',
        run.kept.isEmpty ? 0.0 : run.uploaded / run.kept.length,
        false,
      ),
      ImportPhase.processing => (
        s?.grouping ?? false
            ? 'SORTING OUT REPEATS'
            : 'CUTTING OUT YOUR CLOTHES',
        s == null
            ? 'Getting started'
            : '${s.photosDone} of ${s.photosTotal} photos · we\'ll '
                  'notify you',
        s?.progress ?? 0.0,
        false,
      ),
      ImportPhase.done => (
        '✦ ${s?.piecesAdded ?? 0} NEW PIECES FROM YOUR PHOTOS',
        (s?.duplicatesMerged ?? 0) > 0
            ? '${s!.duplicatesMerged} repeats folded together'
            : null,
        null,
        false,
      ),
      ImportPhase.failed => (
        'WARDROBE IMPORT STOPPED',
        run.error ?? 'Tap to try again',
        null,
        true,
      ),
    };

    final show = title.isNotEmpty;
    return AnimatedSize(
      duration: Motion.dur(context, Motion.content),
      curve: Motion.out,
      alignment: Alignment.topCenter,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Tap(
                onTap: () => context.push('/wardrobe/import'),
                semanticLabel: title,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: alert
                          ? AppColors.red
                          : accent.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.mono(
                                10,
                                color: alert ? AppColors.red : AppColors.cream,
                              ),
                            ),
                            if (line != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                line,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.manrope(
                                  12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                            if (progress != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  color: accent,
                                  backgroundColor: AppColors.deep,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (run.phase == ImportPhase.done ||
                          run.phase == ImportPhase.failed)
                        Tap(
                          semanticLabel: 'Dismiss',
                          onTap: () => ref
                              .read(wardrobeImportProvider.notifier)
                              .dismiss(),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(left: 6, right: 6),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
