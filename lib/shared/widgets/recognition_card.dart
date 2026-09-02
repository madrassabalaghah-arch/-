import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../models/recognition_item.dart';
import 'dashboard_card.dart';

/// An achievement card.
///
/// Milestones and awards use the official gold gradient. Lower tiers use a
/// white surface with a gold accent so gold keeps its meaning.
class RecognitionCard extends StatelessWidget {
  const RecognitionCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final RecognitionItem item;
  final VoidCallback? onTap;

  bool get _isHighlight => item.tier != RecognitionTier.appreciation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground =
        _isHighlight ? AppColors.darkGreen : AppColors.textPrimary;
    final Color secondary = _isHighlight
        ? AppColors.darkGreen.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return DashboardCard(
      onTap: onTap,
      variant: _isHighlight
          ? DashboardCardVariant.gold
          : DashboardCardVariant.info,
      accentColor: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _isHighlight
                      ? AppColors.white.withValues(alpha: 0.45)
                      : AppColors.goldTint,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(item.icon, size: 22, color: AppColors.earthBrown),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      item.detail ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: _isHighlight
                      ? AppColors.white.withValues(alpha: 0.5)
                      : AppColors.goldTint,
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  item.tierLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.earthBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  item.dateLabel,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
