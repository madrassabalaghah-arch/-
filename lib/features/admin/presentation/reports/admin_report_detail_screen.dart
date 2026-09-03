import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/presentation/evidence_viewer.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// One کارگزاری in full, with the evidence attached to it.
///
/// Read-only: reviewing is the mentor's job, so an administrator sees the
/// record and its files without a review action that would bypass them.
class AdminReportDetailScreen extends ConsumerWidget {
  const AdminReportDetailScreen({required this.report, super.key});

  final ReportItem report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<EvidenceItem>> evidence =
        ref.watch(reportEvidenceProvider(report.id));

    return AppScaffold(
      title: AppStrings.reportDetails,
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
                    Expanded(
                      child: Text(
                        report.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(status: report.status, compact: true),
                  ],
                ),
                AppSpacing.gapMd,
                Text(
                  '${AppStrings.graduateName}: ${report.graduateName}',
                  style: theme.textTheme.labelLarge,
                ),
                if (report.activityType != null) ...<Widget>[
                  AppSpacing.gapXxs,
                  Text(report.activityType!, style: theme.textTheme.labelSmall),
                ],
                AppSpacing.gapXxs,
                Text(report.dateLabel, style: theme.textTheme.labelSmall),
                if (report.summary != null &&
                    report.summary!.trim().isNotEmpty) ...<Widget>[
                  AppSpacing.gapLg,
                  Text(report.summary!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.evidence),
          AsyncSection<List<EvidenceItem>>(
            value: evidence,
            isEmpty: (List<EvidenceItem> e) => e.isEmpty,
            emptyTitle: AppStrings.noEvidenceForReport,
            emptyIcon: Icons.folder_open_outlined,
            onRetry: () => ref.invalidate(reportEvidenceProvider(report.id)),
            builder: (BuildContext context, List<EvidenceItem> items) => Column(
              children: <Widget>[
                for (final EvidenceItem item in items)
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
        ],
      ),
    );
  }
}
