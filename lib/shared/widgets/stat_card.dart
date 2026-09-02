import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_theme.dart';
import '../models/dashboard_items.dart';
import 'dashboard_card.dart';

/// A single figure with an Urdu caption.
///
/// The value is expected to arrive already formatted with Urdu digits by
/// whichever provider counted it.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final StatItem item;
  final VoidCallback? onTap;

  /// Maps a tone onto the official palette. No screen picks its own colour.
  static Color colorFor(StatTone tone) {
    switch (tone) {
      case StatTone.green:
        return AppColors.primaryGreen;
      case StatTone.teal:
        return AppColors.tealGreen;
      case StatTone.gold:
        return AppColors.gold;
      case StatTone.olive:
        return AppColors.oliveGreen;
      case StatTone.brown:
        return AppColors.earthBrown;
      case StatTone.neutral:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tone = colorFor(item.tone);

    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Icon(item.icon, size: 20, color: tone),
          ),
          AppSpacing.gapSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              item.value,
              style: AppTextTheme.statValue(tone),
            ),
          ),
          AppSpacing.gapXxs,
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
