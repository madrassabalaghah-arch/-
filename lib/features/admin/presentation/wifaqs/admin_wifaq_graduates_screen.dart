import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The graduates at one leaf of the wifaq hierarchy: either everyone at one
/// institute, or — when [instituteId] is null — everyone in [wifaqId] who
/// has not named an institute at all.
class AdminWifaqGraduatesScreen extends ConsumerWidget {
  const AdminWifaqGraduatesScreen({
    required this.title,
    required this.instituteId,
    required this.wifaqId,
    super.key,
  });

  final String title;
  final String? instituteId;
  final String? wifaqId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ({
      String? instituteId,
      bool includeUnassignedInstitute,
      String? wifaqId
    }) target = (
      instituteId: instituteId,
      includeUnassignedInstitute: instituteId == null,
      wifaqId: wifaqId,
    );
    final AsyncValue<List<GraduateSummary>> graduates =
        ref.watch(adminHierarchyGraduatesProvider(target));

    return SearchableListScreen<GraduateSummary>(
      title: title,
      items: graduates,
      onRefresh: () =>
          ref.refresh(adminHierarchyGraduatesProvider(target).future),
      searchHint: AppStrings.hintSearchGraduate,
      searchText: (GraduateSummary item) =>
          '${item.name} ${item.placeLine ?? ""}',
      emptyIcon: Icons.school_outlined,
      emptyTitle: AppStrings.noGraduatesHere,
      itemBuilder: (BuildContext context, GraduateSummary item) => AppListTile(
        title: item.name,
        subtitle: item.placeLine,
        detail: item.stage,
        avatarText: item.avatarLabel,
        status: item.status,
        progress: item.progress,
        onTap: () => context.push(AppRoutes.adminUser, extra: item),
      ),
    );
  }
}
