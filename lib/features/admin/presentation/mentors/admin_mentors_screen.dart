import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Administration of the mentors.
class AdminMentorsScreen extends ConsumerWidget {
  const AdminMentorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<MentorSummary>(
      title: AppStrings.mentors,
      items: ref.watch(adminMentorsProvider),
      onRefresh: () => ref.refresh(adminMentorsProvider.future),
      searchText: (MentorSummary item) =>
          '${item.name} ${item.placeLine ?? ""}',
      emptyIcon: Icons.supervisor_account_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      actions: <Widget>[
        // For a mentor who is not on the course register. Someone who already
        // has an account is made a mentor from their own screen instead.
        IconButton(
          tooltip: AppStrings.inviteMentor,
          icon: const Icon(Icons.person_add_alt_outlined),
          onPressed: () =>
              context.push(AppRoutes.adminAddStaff, extra: AppRole.mentor),
        ),
      ],
      itemBuilder: (BuildContext context, MentorSummary item) => AppListTile(
        title: item.name,
        subtitle: item.placeLine,
        detail: '${AppStrings.myGraduates}: '
            '${UrduNumbers.fromInt(item.graduateCount)} • '
            '${AppStrings.pendingReviews}: '
            '${UrduNumbers.fromInt(item.pendingReviews)}',
        avatarText: item.avatarLabel,
        status: item.status,
        accentColor: AppColors.oliveGreen,
        // The administration screen works from a profile, so the mentor is
        // passed through in the same shape the graduate list uses.
        onTap: () => context.push(
          AppRoutes.adminUser,
          extra: GraduateSummary(
            id: item.id,
            name: item.name,
            instituteName: item.instituteName,
            city: item.city,
            status: item.status,
          ),
        ),
      ),
    );
  }
}
