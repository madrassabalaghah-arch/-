import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Assessments this mentor has completed.
class MentorEvaluationsScreen extends ConsumerWidget {
  const MentorEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<EvaluationItem>(
      title: AppStrings.assessment,
      items: ref.watch(mentorEvaluationsProvider),
      onRefresh: () => ref.refresh(mentorEvaluationsProvider.future),
      searchText: (EvaluationItem item) => item.title ?? '',
      emptyIcon: Icons.fact_check_outlined,
      itemBuilder: (BuildContext context, EvaluationItem item) => AppListTile(
        title: item.title ?? AppStrings.evaluation,
        subtitle: item.comment,
        detail: item.dateLabel,
        icon: Icons.fact_check_outlined,
        status: item.status,
        progress: item.ratio,
        accentColor: AppColors.gold,
        trailing: Text(
          UrduNumbers.ratio(item.score, item.maxScore),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.earthBrown,
              ),
        ),
      ),
    );
  }
}
