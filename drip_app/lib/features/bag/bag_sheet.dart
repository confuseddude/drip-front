import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/tap.dart';
import 'bag_controller.dart';

/// Opens the shopping-bag sheet.
Future<void> showBagSheet(BuildContext context) {
  return showDripSheet<void>(context, builder: (_) => const _BagSheet());
}

class _BagSheet extends ConsumerWidget {
  const _BagSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bag = ref.watch(bagProvider);
    final total = bag.fold<int>(0, (s, l) => s + l.price);

    return SheetContent(
      title: 'YOUR BAG',
      subtitle: bag.isEmpty
          ? 'Nothing here yet. Shop a fit to add its pieces.'
          : '${bag.length} PIECES',
      children: [
        for (final line in bag)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.elevated)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: AppText.manrope(13, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        line.subtitle,
                        style: AppText.mono(9, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatPrice(line.price),
                  style: AppText.mono(12, color: AppColors.cyan),
                ),
                const SizedBox(width: 12),
                Tap(
                  onTap: () => ref.read(bagProvider.notifier).remove(line.name),
                  semanticLabel: 'Remove ${line.name}',
                  child: Text(
                    '✕',
                    style: AppText.inter(14, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        if (bag.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: AppText.mono(
                  11,
                  color: AppColors.muted,
                  letterSpacing: 1,
                ),
              ),
              Text(formatPrice(total), style: AppText.display(16)),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'CHECKOUT →',
            height: 46,
            radius: 14,
            onPressed: () {
              Navigator.of(context).pop();
              showDripToast(context, 'Checkout unlocks with the store backend');
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'CLEAR BAG',
            style: AppButtonStyle.outline,
            height: 42,
            radius: 14,
            onPressed: () => ref.read(bagProvider.notifier).clear(),
          ),
        ],
      ],
    );
  }
}
