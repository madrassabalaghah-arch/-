import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/presentation/evidence_viewer.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The work filed against one activity: its کارگزاری and their evidence.
typedef ActivityWork = ({
  List<ReportItem> reports,
  List<EvidenceItem> evidence,
});

/// One activity's own screen: what it is, how far this graduate has got, the
/// کارگزاری they have filed against it, and the evidence attached to those.
///
/// Every line is a stored record. Where the activity has no reports yet the
/// section shows its empty state rather than placeholder rows, and the
/// location the brief mentions is absent because no such column exists —
/// showing one would mean inventing it.
class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({required this.activity, super.key});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<ActivityWork> work =
        ref.watch(activityWorkProvider(activity.id));

    return AppScaffold(
      title: AppStrings.activityDetail,
      body: ListView(
        padding: const EdgeInsetsDirectional.only(
          bottom: AppSpacing.bottomSafeArea,
        ),
        children: <Widget>[
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(activity.icon, color: AppColors.oliveGreen),
                    AppSpacing.hGapMd,
                    Expanded(
                      child: Text(
                        activity.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(status: activity.status, compact: true),
                  ],
                ),
                if (activity.detail != null &&
                    activity.detail!.trim().isNotEmpty) ...<Widget>[
                  AppSpacing.gapLg,
                  Text(activity.detail!, style: theme.textTheme.bodyMedium),
                ],
                AppSpacing.gapLg,
                Text(
                  '${AppStrings.completedSteps}: '
                  '${UrduNumbers.ratio(activity.completed, activity.total)}',
                  style: theme.textTheme.labelLarge,
                ),
                AppSpacing.gapSm,
                ClipRRect(
                  borderRadius: AppRadius.radiusPill,
                  child: LinearProgressIndicator(
                    value: activity.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.lightGray,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.oliveGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.relatedReports),
          AsyncSection<ActivityWork>(
            value: work,
            isEmpty: (ActivityWork w) => w.reports.isEmpty,
            emptyTitle: AppStrings.noReportsForActivity,
            emptyIcon: Icons.description_outlined,
            onRetry: () => ref.invalidate(activityWorkProvider(activity.id)),
            builder: (BuildContext context, ActivityWork w) => Column(
              children: <Widget>[
                for (final ReportItem report in w.reports)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.md,
                    ),
                    child: AppListTile(
                      title: report.title,
                      subtitle: report.summary,
                      detail: report.dateLabel,
                      icon: Icons.description_outlined,
                      status: report.status,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.evidence),
          AsyncSection<ActivityWork>(
            value: work,
            isEmpty: (ActivityWork w) => w.evidence.isEmpty,
            emptyTitle: AppStrings.noEvidenceForActivity,
            emptyIcon: Icons.folder_open_outlined,
            onRetry: () => ref.invalidate(activityWorkProvider(activity.id)),
            builder: (BuildContext context, ActivityWork w) => Column(
              children: <Widget>[
                for (final EvidenceItem item in w.evidence)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.md,
                    ),
                    child: AppListTile(
                      title: item.title,
                      subtitle: '${item.typeLabel} • ${item.sizeLabel}',
                      detail: item.dateLabel,
                      icon: item.icon,
                      status: item.status,
                      accentColor: AppColors.tealGreen,
                      onTap: () => openEvidence(context, ref, item),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.reviewAndFeedback),
          AsyncSection<List<EvaluationItem>>(
            value: ref.watch(graduateEvaluationsProvider).whenData(
                  (List<EvaluationItem> all) => all
                      .where((EvaluationItem e) =>
                          (work.value?.reports ?? const <ReportItem>[])
                              .any((ReportItem r) => r.id == e.reportId))
                      .toList(),
                ),
            isEmpty: (List<EvaluationItem> e) => e.isEmpty,
            emptyTitle: AppStrings.noReviewYet,
            emptyIcon: Icons.fact_check_outlined,
            onRetry: () => ref.invalidate(graduateEvaluationsProvider),
            builder: (BuildContext context, List<EvaluationItem> reviews) =>
                Column(
              children: <Widget>[
                for (final EvaluationItem e in reviews)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.md,
                    ),
                    child: AppListTile(
                      title: e.title ?? AppStrings.reviewStepReport,
                      subtitle: e.comment,
                      detail: e.mentorName == null
                          ? null
                          : '${AppStrings.mentorLabel}: ${e.mentorName}',
                      icon: Icons.fact_check_outlined,
                      accentColor: AppColors.oliveGreen,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
