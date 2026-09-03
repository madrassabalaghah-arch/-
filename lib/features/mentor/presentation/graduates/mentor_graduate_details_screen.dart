import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_navigation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The detail view of a single graduate.
///
/// The demonstration data has no selection mechanism yet, so the first record
/// is shown. Selecting a specific graduate arrives with real data.
class MentorGraduateDetailsScreen extends ConsumerWidget {
  const MentorGraduateDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<GraduateSummary> graduates =
        ref.watch(mentorGraduatesProvider).value ?? const <GraduateSummary>[];
    final List<ReportItem> reports =
        ref.watch(mentorReportsProvider).value ?? const <ReportItem>[];

    if (graduates.isEmpty) {
      return const AppScaffold(
        title: AppStrings.graduateDetails,
        body: EmptyState(),
      );
    }

    final GraduateSummary graduate = graduates.first;
    final List<ReportItem> graduateReports = reports
        .where((ReportItem r) => r.graduateName == graduate.name)
        .toList();

    return AppScaffold(
      title: AppStrings.graduateDetails,
      body: ListView(
        children: <Widget>[
          DashboardCard(
            variant: DashboardCardVariant.gradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  graduate.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                  ),
                ),
                AppSpacing.gapXs,
                Text(
                  graduate.placeLine ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.88),
                  ),
                ),
                AppSpacing.gapLg,
                Text(
                  '${AppStrings.trainingStage}: ${graduate.stage ?? ""}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                  ),
                ),
                AppSpacing.gapMd,
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: graduate.progress,
                    minHeight: 10,
                    backgroundColor:
                        AppColors.white.withValues(alpha: 0.24),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                Text(
                  UrduNumbers.percent((graduate.progress * 100).round()),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.reportStatus),
          DashboardCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    graduate.lastActivity ?? AppStrings.noRecordsYet,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                StatusBadge(status: graduate.status),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.myReports),
          if (graduateReports.isEmpty)
            const DashboardCard(child: EmptyState(compact: true))
          else
            for (final ReportItem report in graduateReports) ...<Widget>[
              AppListTile(
                title: report.title,
                subtitle: report.summary,
                detail: '${report.activityType ?? ""} • ${report.dateLabel}',
                icon: Icons.description_outlined,
                status: report.status,
                onTap: () => context.goToRoute(AppRoutes.mentorReportDetails,
                    extra: report),
              ),
              AppSpacing.gapMd,
            ],
          AppSpacing.gapMd,
          PrimaryButton(
            label: AppStrings.reportReview,
            icon: Icons.rate_review_outlined,
            onPressed: () => context.goToRoute(AppRoutes.mentorReportReview),
          ),
        ],
      ),
    );
  }
}
