import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The results of the mentor evaluations of a graduate.
class GraduateEvaluationsScreen extends ConsumerWidget {
  const GraduateEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<EvaluationItem>(
      title: AppStrings.evaluationResults,
      items: ref.watch(graduateEvaluationsProvider),
      onRefresh: () => ref.refresh(graduateEvaluationsProvider.future),
      searchText: (EvaluationItem item) => item.title ?? '',
      emptyIcon: Icons.fact_check_outlined,
      // The whole جائزہ, not just its first line: تبصرہ, قابلِ تحسین and
      // رہنمائی each under their own heading. رہنمائی used to arrive as a
      // separate message; it is part of the جائزہ now.
      itemBuilder: (BuildContext context, EvaluationItem item) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
        child: JaizaCard(item: item),
      ),
    );
  }
}
