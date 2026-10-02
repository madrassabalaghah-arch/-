import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
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
      searchText: (EvaluationItem item) =>
          '${item.title ?? ''} ${item.graduateName ?? ''}',
      emptyIcon: Icons.fact_check_outlined,
      itemBuilder: (BuildContext context, EvaluationItem item) => AppListTile(
        title: item.title ?? AppStrings.evaluation,
        subtitle: item.comment,
        // Which فاضل / فاضلہ this review was written for.
        detail: item.graduateName == null
            ? item.dateLabel
            : '${item.graduateName} • ${item.dateLabel}',
        icon: Icons.fact_check_outlined,
        status: item.status,
        accentColor: AppColors.gold,
      ),
    );
  }
}
