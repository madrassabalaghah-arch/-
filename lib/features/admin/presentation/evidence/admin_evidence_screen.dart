import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/presentation/evidence_viewer.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Every uploaded evidence file, for an administrator.
///
/// The query carries no ownership filter; the `evidence select permitted`
/// policy is what decides the rows, so this screen shows an administrator
/// everything and would show anyone else only their own.
class AdminEvidenceScreen extends ConsumerWidget {
  const AdminEvidenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<EvidenceItem>(
      title: AppStrings.evidence,
      items: ref.watch(adminEvidenceProvider),
      onRefresh: () => ref.refresh(adminEvidenceProvider.future),
      searchHint: AppStrings.searchEvidenceHint,
      searchText: (EvidenceItem item) =>
          '${item.title} ${item.graduateName ?? ''} ${item.reportTitle ?? ''} '
          '${item.typeLabel}',
      emptyIcon: Icons.folder_open_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      // The owner leads each row, and the کارگزاری it belongs to is on the
      // line below, so a file is never an anonymous item in a pile.
      itemBuilder: (BuildContext context, EvidenceItem item) => AppListTile(
        title: item.graduateName == null
            ? item.title
            : '${item.graduateLabel}: ${item.graduateName}',
        subtitle: item.graduateName == null
            ? '${item.typeLabel} • ${item.reviewLabel}'
            : '${item.title} • ${item.typeLabel} • ${item.reviewLabel}',
        detail: <String>[
          if (item.reportTitle != null)
            '${AppStrings.relatedKarGuzari}: ${item.reportTitle}',
          item.dateLabel,
          if (item.reviewNote != null) item.reviewNote!,
        ].join(' • '),
        icon: item.icon,
        status: item.status,
        accentColor: AppColors.tealGreen,
        onTap: () => openEvidence(context, ref, item),
        trailing: PopupMenuButton<AppStatus>(
          tooltip: AppStrings.reviewEvidence,
          icon: const Icon(Icons.fact_check_outlined),
          onSelected: (AppStatus verdict) async {
            await ref
                .read(mentorRepositoryProvider)
                .reviewEvidence(evidenceId: item.id, verdict: verdict);
            ref.invalidate(adminEvidenceProvider);
          },
          itemBuilder: (BuildContext context) =>
              const <PopupMenuEntry<AppStatus>>[
            PopupMenuItem<AppStatus>(
              value: AppStatus.completed,
              child: Text(AppStrings.evidenceApproved),
            ),
            PopupMenuItem<AppStatus>(
              value: AppStatus.revisionRequired,
              child: Text(AppStrings.evidenceNeedsInfo),
            ),
          ],
        ),
      ),
    );
  }
}
