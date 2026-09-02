import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The graduate list of submitted performance reports.
class GraduateReportsScreen extends ConsumerWidget {
  const GraduateReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<ReportItem>(
      title: AppStrings.myReports,
      items: ref.watch(graduateReportsProvider),
      onRefresh: () => ref.refresh(graduateReportsProvider.future),
      searchHint: AppStrings.hintSearchReport,
      searchText: (ReportItem item) => '${item.title} ${item.activityType}',
      emptyIcon: Icons.description_outlined,
      emptyTitle: AppStrings.noReportsYet,
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.newReport,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => context.push(AppRoutes.graduateReportEditor),
        ),
      ],
      itemBuilder: (BuildContext context, ReportItem item) => AppListTile(
        title: item.title,
        subtitle: item.summary,
        detail: '${item.activityType} • ${item.dateLabel}',
        icon: Icons.description_outlined,
        status: item.status,
        // Only a draft can be edited; the editor locks the rest.
        onTap: () => context.push(
          AppRoutes.graduateReportEditor,
          extra: item,
        ),
      ),
    );
  }
}
