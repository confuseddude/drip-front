import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import '../../data/api/api_client.dart';
import '../../data/providers.dart';
import '../../data/repositories/report_repository.dart';

/// Opens "Report a bug" for [screen] (and the fit on it, [fitId], or the
/// wardrobe piece, [itemId]). [kind] pre-picks what's wrong.
Future<void> showReportBug(
  BuildContext context, {
  required String screen,
  String? fitId,
  String? itemId,
  String? kind,
}) async {
  final outcome = await showDripSheet<ReportOutcome>(
    context,
    builder: (_) => ReportBugSheet(
      screen: screen,
      fitId: fitId,
      itemId: itemId,
      initialKind: kind,
    ),
  );
  if (outcome == null || !context.mounted) return;
  showDripToast(
    context,
    outcome == ReportOutcome.sent
        ? 'Thanks. Your report is with the Drip team'
        : "Thanks. It'll send when Drip can be reached",
  );
}

/// What went wrong, in a few words, plus the context to find it: the screen,
/// the fit (if the user keeps it attached), the app version and the phone's
/// OS. Never photos or the account's content.
class ReportBugSheet extends ConsumerStatefulWidget {
  const ReportBugSheet({
    super.key,
    required this.screen,
    this.fitId,
    this.itemId,
    this.initialKind,
  });
  final String screen;
  final String? fitId;
  final String? itemId;
  final String? initialKind;

  static const kinds = [
    ('broken', 'Something broke'),
    ('wrong_piece', 'Wrong piece or link'),
    ('image', 'Picture looks off'),
    ('slow', 'Slow or stuck'),
    ('other', 'Something else'),
  ];

  @override
  ConsumerState<ReportBugSheet> createState() => _ReportBugSheetState();
}

class _ReportBugSheetState extends ConsumerState<ReportBugSheet> {
  final _message = TextEditingController();
  late String? _kind = widget.initialKind;
  bool _attachFit = true;
  bool _sending = false;
  String? _error;

  static const _maxLength = 1000;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// A piece's report can go without words: the attached cut-out says it.
  bool get _ready =>
      _kind != null &&
      (_message.text.trim().length >= 3 || (_piece && _attachFit));

  bool get _piece => widget.itemId != null;

  /// Sent when a piece's report has no words.
  static const _pieceFallback = 'The cut-out of this piece looks off.';

  Future<void> _send() async {
    if (!_ready || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    var text = _message.text.trim();
    if (text.length < 3) text = _pieceFallback;
    try {
      final outcome = await ref
          .read(reportRepositoryProvider)
          .submit(
            BugReport(
              kind: _kind!,
              message: text.length > _maxLength
                  ? text.substring(0, _maxLength)
                  : text,
              screen: widget.screen,
              fitId: _attachFit ? widget.fitId : null,
              wardrobeItemId: _attachFit ? widget.itemId : null,
              appVersion: Env.appVersion,
              platform: BugReport.thisPlatform(),
            ),
          );
      Haptics.commit();
      if (mounted) Navigator.of(context).pop(outcome);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.friendly);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't send it. Try again.");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetContent(
      title: 'REPORT A BUG',
      subtitle: 'Tell us what went wrong. The Drip team reads every report.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (id, label) in ReportBugSheet.kinds)
              _KindChip(
                label: label,
                selected: _kind == id,
                onTap: () {
                  Haptics.tick();
                  setState(() => _kind = id);
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        DripField(
          controller: _message,
          hint: 'What happened? What did you expect?',
          radius: 14,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (_) => setState(() {}),
          errorText: _error,
        ),
        if (widget.fitId != null || _piece) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _piece ? 'Attach this piece' : 'Attach this fit',
                      style: AppText.manrope(13, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'So we can find it.',
                      style: AppText.manrope(11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              DripSwitch(
                value: _attachFit,
                onChanged: (v) => setState(() => _attachFit = v),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Sent with it: the screen, the app version and your phone\'s '
          'system version${widget.fitId != null && _attachFit ? ', and the fit\'s id' : ''}. '
          'Never your photos.',
          style: AppText.manrope(11, color: AppColors.dim, lineHeight: 16),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'SEND REPORT',
          height: 46,
          loading: _sending,
          onPressed: _ready ? _send : null,
        ),
      ],
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      scale: 0.95,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: Motion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.cream : AppColors.base,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.cream : AppColors.elevated,
          ),
        ),
        child: Text(
          label,
          style: AppText.manrope(
            12,
            weight: FontWeight.w600,
            color: selected ? AppColors.base : AppColors.cream,
          ),
        ),
      ),
    );
  }
}
