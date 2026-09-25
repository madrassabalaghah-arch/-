import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

/// جائزے: every review and every piece of guidance mentors have written,
/// each one saying which mentor wrote it, for which فاضل / فاضلہ, and on
/// which کارگزاری. Without those three a remark such as "بہت خوب" belongs
/// to nobody.
class AdminEvaluationsScreen extends ConsumerWidget {
  const AdminEvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EvaluationItem>> reviews =
        ref.watch(adminEvaluationsProvider);
    final AsyncValue<List<MentorFeedback>> feedback =
        ref.watch(adminFeedbackProvider);

    Future<void> refresh() async {
      ref.invalidate(adminEvaluationsProvider);
      ref.invalidate(adminFeedbackProvider);
      await Future.wait<Object?>(<Future<Object?>>[
        ref.read(adminEvaluationsProvider.future),
        ref.read(adminFeedbackProvider.future),
      ]);
    }

    return AppScaffold(
      title: AppStrings.allReviews,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            const SectionHeader(title: AppStrings.allReviews),
            AsyncSection<List<EvaluationItem>>(
              value: reviews,
              isEmpty: (List<EvaluationItem> items) => items.isEmpty,
              emptyTitle: AppStrings.noRecordsYet,
              emptyIcon: Icons.fact_check_outlined,
              onRetry: () => ref.invalidate(adminEvaluationsProvider),
              builder: (BuildContext context, List<EvaluationItem> items) =>
                  Column(
                children: <Widget>[
                  for (final EvaluationItem e in items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.md,
                      ),
                      child: AppListTile(
                        title: e.graduateName ?? AppStrings.graduates,
                        subtitle: e.comment,
                        detail: <String>[
                          '${AppStrings.mentorLabel}: '
                              '${e.mentorName ?? AppStrings.mentorNotRecorded}',
                          if (e.title != null)
                            '${AppStrings.relatedKarGuzari}: ${e.title}',
                          e.dateLabel,
                        ].join(' • '),
                        icon: Icons.fact_check_outlined,
                        accentColor: AppColors.oliveGreen,
                        trailing: Text(
                          UrduNumbers.ratio(e.score, e.maxScore),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: AppColors.earthBrown),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.gapXl,
            const SectionHeader(title: AppStrings.feedbackAndGuidance),
            AsyncSection<List<MentorFeedback>>(
              value: feedback,
              isEmpty: (List<MentorFeedback> items) => items.isEmpty,
              emptyTitle: AppStrings.noFeedbackYet,
              emptyIcon: Icons.forum_outlined,
              onRetry: () => ref.invalidate(adminFeedbackProvider),
              builder: (BuildContext context, List<MentorFeedback> items) =>
                  Column(
                children: <Widget>[
                  for (final MentorFeedback f in items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.md,
                      ),
                      child: AppListTile(
                        title: f.graduateName ?? AppStrings.graduates,
                        subtitle: f.message,
                        detail: <String>[
                          '${AppStrings.mentorLabel}: '
                              '${f.mentorName ?? AppStrings.mentorNotRecorded}',
                          if (f.reportTitle != null)
                            '${AppStrings.relatedKarGuzari}: ${f.reportTitle}',
                          f.dateLabel,
                        ].join(' • '),
                        icon: Icons.forum_outlined,
                        accentColor: AppColors.gold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
