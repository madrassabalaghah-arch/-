import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_navigation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The graduates under this mentor.
class MentorGraduatesScreen extends ConsumerWidget {
  const MentorGraduatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<GraduateSummary>(
      title: AppStrings.myGraduates,
      items: ref.watch(mentorGraduatesProvider),
      onRefresh: () => ref.refresh(mentorGraduatesProvider.future),
      searchHint: AppStrings.hintSearchGraduate,
      searchText: (GraduateSummary item) =>
          '${item.name} ${item.placeLine ?? ""}',
      emptyIcon: Icons.groups_outlined,
      itemBuilder: (BuildContext context, GraduateSummary item) => AppListTile(
        title: item.name,
        subtitle: item.placeLine,
        detail: '${item.stage} • ${item.lastActivity}',
        avatarText: item.avatarLabel,
        status: item.status,
        progress: item.progress,
        onTap: () => context.goToRoute(AppRoutes.mentorGraduateDetails),
      ),
    );
  }
}
