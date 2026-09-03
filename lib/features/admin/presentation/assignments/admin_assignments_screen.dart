import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Administration of the duties assigned to graduates.
class AdminAssignmentsScreen extends ConsumerWidget {
  const AdminAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<TaskItem>(
      title: AppStrings.assignments,
      items: ref.watch(adminAssignmentsProvider),
      onRefresh: () => ref.refresh(adminAssignmentsProvider.future),
      searchText: (TaskItem item) => '${item.title} ${item.assignedToName}',
      emptyIcon: Icons.assignment_ind_outlined,
      itemBuilder: (BuildContext context, TaskItem item) => AppListTile(
        title: item.title,
        subtitle: '${AppStrings.graduateName}: ${item.assignedToName}',
        detail: item.dueLabel,
        icon: Icons.assignment_ind_outlined,
        status: item.status,
        accentColor: AppColors.oliveGreen,
      ),
    );
  }
}
