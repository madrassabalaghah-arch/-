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

/// The institutes inside one wifaq, each with its فاضل / فاضلہ counts.
///
/// A tile with no [InstituteDirectoryEntry.instituteId] is not an institute —
/// it is the bucket of graduates in this wifaq who have not named one yet,
/// kept visible rather than dropped so that gap stays obvious.
class AdminWifaqInstitutesScreen extends ConsumerWidget {
  const AdminWifaqInstitutesScreen({required this.wifaq, super.key});

  final WifaqDirectoryEntry wifaq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InstituteDirectoryEntry>> institutes =
        ref.watch(adminInstituteDirectoryProvider(wifaq.wifaqId));

    return SearchableListScreen<InstituteDirectoryEntry>(
      title: wifaq.displayName,
      items: institutes,
      onRefresh: () =>
          ref.refresh(adminInstituteDirectoryProvider(wifaq.wifaqId).future),
      searchText: (InstituteDirectoryEntry item) =>
          '${item.displayName} ${item.city ?? ""}',
      emptyIcon: Icons.location_city_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      itemBuilder: (BuildContext context, InstituteDirectoryEntry item) =>
          AppListTile(
        title: item.displayName,
        subtitle: '${AppStrings.maleLabel} ${UrduNumbers.fromInt(item.maleCount)}'
            '   ${AppStrings.femaleLabel} ${UrduNumbers.fromInt(item.femaleCount)}',
        detail:
            '${AppStrings.totalGraduates}: ${UrduNumbers.fromInt(item.graduateTotal)}',
        icon: Icons.location_city_outlined,
        status: item.isUnassigned ? null : item.status,
        accentColor: item.isUnassigned ? AppColors.gray : AppColors.tealGreen,
        onTap: () => context.push(
          AppRoutes.adminWifaqGraduates,
          extra: (
            title: item.displayName,
            instituteId: item.instituteId,
            wifaqId: wifaq.wifaqId,
          ),
        ),
      ),
    );
  }
}
