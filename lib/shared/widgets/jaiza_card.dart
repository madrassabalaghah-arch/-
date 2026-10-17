import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/models.dart';
import 'dashboard_card.dart';

/// One مربی's جائزہ, in all the parts that were written.
///
/// A جائزہ is تبصرہ, قابلِ تحسین and رہنمائی — words under their own
/// headings. There is deliberately nothing numeric to show: no mark, no
/// ratio, no total. [EvaluationItem.parts] returns only the parts that
/// actually carry text, so an empty heading is never printed.
class JaizaCard extends StatelessWidget {
  const JaizaCard({required this.item, this.showGraduate = false, super.key});

  final EvaluationItem item;

  /// Names the فاضل as well as the مربی. The منتظم needs both; a فاضل
  /// reading their own جائزہ needs only the مربی.
  final bool showGraduate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<({String label, String text})> parts = item.parts;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(item.title ?? AppStrings.evaluation,
              style: theme.textTheme.titleSmall),
          AppSpacing.gapXxs,
          // Who wrote it, about whom, and when — built from the parts that
          // exist, so a missing name never prints as the word "null".
          Text(
            <String>[
              '${AppStrings.mentorLabel}: '
                  '${item.mentorName ?? AppStrings.nameNotRecorded}',
              ?showGraduate
                  ? '${AppStrings.graduateName}: '
                      '${item.graduateName ?? AppStrings.nameNotRecorded}'
                  : null,
              item.dateLabel,
            ].join(' • '),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.primaryGreen),
          ),
          if (parts.isEmpty) ...<Widget>[
            AppSpacing.gapSm,
            Text(AppStrings.noReviewYet, style: theme.textTheme.labelSmall),
          ],
          for (final ({String label, String text}) part in parts) ...<Widget>[
            AppSpacing.gapMd,
            Text(part.label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.gray)),
            AppSpacing.gapXxs,
            Text(part.text, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
