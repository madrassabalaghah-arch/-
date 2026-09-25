import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
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
          // Which کارگزاری the guidance followed, when it followed one.
          if (feedback.reportTitle != null) ...<Widget>[
            AppSpacing.gapXs,
            Text(
              '${AppStrings.relatedKarGuzari}: ${feedback.reportTitle}',
              style: theme.textTheme.labelSmall,
            ),
          ],
          AppSpacing.gapMd,
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  // Named, so the graduate knows which مربی is speaking.
                  feedback.mentorName == null
                      ? AppStrings.mentorNotRecorded
                      : '${AppStrings.mentorLabel}: ${feedback.mentorName}',
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
