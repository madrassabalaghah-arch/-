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
      searchText: (EvidenceItem item) => '${item.title} ${item.typeLabel}',
      emptyIcon: Icons.folder_open_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      itemBuilder: (BuildContext context, EvidenceItem item) => AppListTile(
        title: item.title,
        subtitle: '${item.typeLabel} • ${item.reviewLabel}',
        detail: item.reviewNote == null
            ? item.dateLabel
            : '${item.dateLabel} — ${item.reviewNote}',
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
