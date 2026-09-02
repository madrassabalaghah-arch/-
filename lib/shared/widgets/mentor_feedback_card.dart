import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/work_items.dart';
import 'dashboard_card.dart';

/// Guidance written by a mentor, shown on the graduate dashboard.
class MentorFeedbackCard extends StatelessWidget {
  const MentorFeedbackCard({super.key, required this.feedback});

  final MentorFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DashboardCard(
      variant: DashboardCardVariant.info,
      accentColor: AppColors.tealGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.record_voice_over_outlined,
                size: 20,
                color: AppColors.tealGreen,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  feedback.subject,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(feedback.message, style: theme.textTheme.bodySmall),
          AppSpacing.gapMd,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  feedback.mentorName ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(feedback.dateLabel, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
