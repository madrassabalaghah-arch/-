import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/presentation/evidence_viewer.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Evidence submitted by the graduates under this mentor.
class MentorEvidenceScreen extends ConsumerWidget {
  const MentorEvidenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<EvidenceItem>(
      title: AppStrings.evidence,
      items: ref.watch(mentorEvidenceProvider),
      onRefresh: () => ref.refresh(mentorEvidenceProvider.future),
      searchHint: AppStrings.searchEvidenceHint,
      searchText: (EvidenceItem item) =>
          '${item.title} ${item.graduateName ?? ''} ${item.reportTitle ?? ''} '
          '${item.typeLabel}',
      emptyIcon: Icons.folder_open_outlined,
      // Whose evidence it is comes first: a file on its own says nothing
      // about who did the work.
      itemBuilder: (BuildContext context, EvidenceItem item) => AppListTile(
        title: item.graduateName == null
            ? item.title
            : '${item.graduateLabel}: ${item.graduateName}',
        subtitle: item.graduateName == null
            ? '${item.typeLabel} • ${item.sizeLabel}'
            : '${item.title} • ${item.typeLabel}',
        detail: item.reportTitle == null
            ? item.dateLabel
            : '${AppStrings.relatedKarGuzari}: ${item.reportTitle}'
                ' • ${item.dateLabel}',
        icon: item.icon,
        status: item.status,
        accentColor: AppColors.tealGreen,
        onTap: () => openEvidence(context, ref, item),
      ),
    );
  }
}
