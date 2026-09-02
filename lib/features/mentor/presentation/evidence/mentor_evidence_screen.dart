import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
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
      searchText: (EvidenceItem item) => '${item.title} ${item.typeLabel}',
      emptyIcon: Icons.folder_open_outlined,
      itemBuilder: (BuildContext context, EvidenceItem item) => AppListTile(
        title: item.title,
        subtitle: '${item.typeLabel} • ${item.sizeLabel}',
        detail: item.dateLabel,
        icon: item.icon,
        status: item.status,
        accentColor: AppColors.tealGreen,
        onTap: () {},
      ),
    );
  }
}
