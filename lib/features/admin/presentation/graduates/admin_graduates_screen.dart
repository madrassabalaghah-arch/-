import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Administration of every graduate in the system.
class AdminGraduatesScreen extends ConsumerWidget {
  const AdminGraduatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<GraduateSummary>(
      title: AppStrings.graduates,
      items: ref.watch(adminGraduatesProvider),
      onRefresh: () => ref.refresh(adminGraduatesProvider.future),
      searchHint: AppStrings.hintSearchGraduate,
      searchText: (GraduateSummary item) =>
          '${item.name} ${item.placeLine ?? ""}',
      emptyIcon: Icons.school_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      itemBuilder: (BuildContext context, GraduateSummary item) => AppListTile(
        title: item.name,
        subtitle: item.placeLine,
        detail: item.stage,
        avatarText: item.avatarLabel,
        status: item.status,
        progress: item.progress,
        onTap: () =>
            context.push(AppRoutes.adminUser, extra: item),
      ),
    );
  }
}
