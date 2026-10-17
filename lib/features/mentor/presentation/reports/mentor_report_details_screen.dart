import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_navigation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The full content of a single report together with its evidence.
class MentorReportDetailsScreen extends ConsumerWidget {
  const MentorReportDetailsScreen({required this.report, super.key});

  /// The report that was tapped. Previously this screen read the first report
  /// in the mentor's queue no matter which row opened it, so every row showed
  /// the same content.
  final ReportItem report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<EvidenceItem> evidence =
        (ref.watch(mentorEvidenceProvider).value ?? const <EvidenceItem>[])
            .where((EvidenceItem e) => e.reportId == report.id)
            .toList();

    return AppScaffold(
      title: AppStrings.reportDetails,
      body: ListView(
        children: <Widget>[
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        report.title,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    StatusBadge(status: report.status),
                  ],
                ),
                AppSpacing.gapMd,
                _DetailRow(
                  label: AppStrings.graduateName,
                  value: report.graduateName ?? '',
                ),
                _DetailRow(
                  label: AppStrings.labelSelectActivity,
                  value: report.activityType ?? '',
                ),
                _DetailRow(
                  label: AppStrings.labelReportTitle,
                  value: report.title,
                ),
                const Divider(),
                Text(
                  AppStrings.labelReportDetail,
                  style: theme.textTheme.labelLarge,
                ),
                AppSpacing.gapSm,
                Text(report.summary ?? '', style: theme.textTheme.bodyMedium),
                AppSpacing.gapMd,
                Text(report.dateLabel, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.evidence),
          if (evidence.isEmpty)
            const DashboardCard(child: EmptyState(compact: true))
          else
            for (final EvidenceItem item in evidence) ...<Widget>[
              AppListTile(
                title: item.title,
                subtitle: '${item.typeLabel} • ${item.sizeLabel}',
                detail: item.dateLabel,
                icon: item.icon,
                status: item.status,
                accentColor: AppColors.tealGreen,
              ),
              AppSpacing.gapMd,
            ],
          AppSpacing.gapMd,
          PrimaryButton(
            label: AppStrings.reportReview,
            icon: Icons.rate_review_outlined,
            onPressed: () =>
                context.goToRoute(AppRoutes.mentorReportReview, extra: report),
          ),
        ],
      ),
    );
  }
}

/// A label and value pair inside a detail card.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: theme.textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
