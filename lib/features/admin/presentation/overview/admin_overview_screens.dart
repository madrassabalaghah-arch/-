import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// ادارے: every institute across all wifaqs, with its فاضل / فاضلہ counts.
/// Opening one lists its graduates, the same leaf the wifaq hierarchy reaches.
class AdminInstitutesScreen extends ConsumerWidget {
  const AdminInstitutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<InstituteDirectoryEntry>(
      title: AppStrings.allInstitutes,
      items: ref.watch(adminInstitutesProvider),
      onRefresh: () => ref.refresh(adminInstitutesProvider.future),
      searchText: (InstituteDirectoryEntry i) =>
          '${i.displayName} ${i.wifaqName ?? ''} ${i.city ?? ''}',
      emptyIcon: Icons.location_city_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      itemBuilder: (BuildContext context, InstituteDirectoryEntry i) =>
          AppListTile(
        title: i.displayName,
        subtitle: i.wifaqName ?? AppStrings.unassignedWifaq,
        detail: '${AppStrings.maleLabel} ${UrduNumbers.fromInt(i.maleCount)}'
            '   ${AppStrings.femaleLabel} ${UrduNumbers.fromInt(i.femaleCount)}'
            '   •   ${AppStrings.totalGraduates}: '
            '${UrduNumbers.fromInt(i.graduateTotal)}',
        icon: Icons.location_city_outlined,
        accentColor: AppColors.tealGreen,
        onTap: () => context.goToRoute(
          AppRoutes.adminWifaqGraduates,
          extra: (
            title: i.displayName,
            instituteId: i.instituteId,
            wifaqId: null,
          ),
        ),
      ),
    );
  }
}

/// جائزے: every evaluation mentors have written.
class AdminEvaluationsScreen extends ConsumerWidget {
  const AdminEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<EvaluationItem>(
      title: AppStrings.allReviews,
      items: ref.watch(adminEvaluationsProvider),
      onRefresh: () => ref.refresh(adminEvaluationsProvider.future),
      searchText: (EvaluationItem e) => '${e.title ?? ''} ${e.comment ?? ''}',
      emptyIcon: Icons.fact_check_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      itemBuilder: (BuildContext context, EvaluationItem e) => AppListTile(
        title: e.title ?? AppStrings.reviewStepReport,
        subtitle: e.comment,
        detail: UrduNumbers.fromInt(e.score),
        icon: Icons.fact_check_outlined,
        accentColor: AppColors.oliveGreen,
      ),
    );
  }
}

/// رپورٹس: کارگزاری counted by status and by category, from live rows.
class AdminStatisticsScreen extends ConsumerWidget {
  const AdminStatisticsScreen({super.key});

  static String _label(({String section, String label, int total}) row) {
    if (row.section == 'status') {
      return AppStatusX.fromDb(row.label).urduLabel;
    }
    return row.label == 'uncategorised' ? AppStrings.noData : row.label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: AppStrings.statisticsReports,
      body: AsyncSection<List<({String section, String label, int total})>>(
        value: ref.watch(adminStatisticsReportProvider),
        isEmpty: (List<({String section, String label, int total})> r) =>
            r.isEmpty,
        emptyTitle: AppStrings.noRecordsYet,
        emptyIcon: Icons.insights_outlined,
        onRetry: () => ref.invalidate(adminStatisticsReportProvider),
        builder: (
          BuildContext context,
          List<({String section, String label, int total})> rows,
        ) =>
            ListView(
          children: <Widget>[
            for (final (String, String) part in const <(String, String)>[
              ('status', AppStrings.reviewStepAssessment),
              ('category', AppStrings.category),
            ]) ...<Widget>[
              SectionHeader(title: part.$2),
              for (final ({String section, String label, int total}) row
                  in rows.where((r) => r.section == part.$1))
                AppListTile(
                  title: _label(row),
                  trailing: Text(
                    UrduNumbers.fromInt(row.total),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  icon: part.$1 == 'status'
                      ? Icons.flag_outlined
                      : Icons.category_outlined,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
