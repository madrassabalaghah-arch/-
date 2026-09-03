import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Every report in the system.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<ReportItem>(
      title: AppStrings.allReports,
      items: ref.watch(adminReportsProvider),
      onRefresh: () => ref.refresh(adminReportsProvider.future),
      searchHint: AppStrings.hintSearchReport,
      searchText: (ReportItem item) => '${item.title} ${item.graduateName}',
      emptyIcon: Icons.description_outlined,
      itemBuilder: (BuildContext context, ReportItem item) => AppListTile(
        title: item.title,
        subtitle: '${AppStrings.graduateName}: ${item.graduateName}',
        detail: '${item.activityType} • ${item.dateLabel}',
        icon: Icons.description_outlined,
        status: item.status,
      ),
    );
  }
}
