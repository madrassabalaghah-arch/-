import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/urdu_numbers.dart';
import '../models/dashboard_items.dart';
import 'dashboard_card.dart';

/// The training journey card.
///
/// This is one of the few surfaces allowed to use the official green gradient,
/// because it is the primary emphasis of the graduate dashboard.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.journey,
  });

  final JourneyProgress journey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const Color onGradient = AppColors.white;

    return DashboardCard(
      variant: DashboardCardVariant.gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.route_outlined, color: onGradient, size: 22),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  AppStrings.myJourney,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onGradient,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: onGradient.withValues(alpha: 0.18),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  UrduNumbers.percent(journey.percent),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onGradient,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          _InfoRow(
            label: AppStrings.trainingStage,
            value: journey.stageLabel,
          ),
          AppSpacing.gapSm,
          _InfoRow(
            label: AppStrings.currentStanding,
            value: journey.statusLabel,
          ),
          AppSpacing.gapLg,
          ClipRRect(
            borderRadius: AppRadius.radiusPill,
            child: LinearProgressIndicator(
              value: journey.progress,
              minHeight: 10,
              backgroundColor: onGradient.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          AppSpacing.gapSm,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${AppStrings.completedSteps}: '
                  '${UrduNumbers.ratio(journey.completedSteps, journey.totalSteps)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onGradient.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: onGradient.withValues(alpha: 0.14),
              borderRadius: AppRadius.radiusMd,
            ),
            child: Text(
              '${AppStrings.nextStep}: ${journey.nextStepLabel}',
              style: theme.textTheme.bodySmall?.copyWith(color: onGradient),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.82),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
