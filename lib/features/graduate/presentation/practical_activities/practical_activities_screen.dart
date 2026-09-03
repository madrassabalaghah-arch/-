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

/// The practical activities a graduate records work against.
class PracticalActivitiesScreen extends ConsumerWidget {
  const PracticalActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<ActivityItem>(
      title: AppStrings.practicalActivities,
      items: ref.watch(graduateActivitiesProvider),
      onRefresh: () => ref.refresh(graduateActivitiesProvider.future),
      searchText: (ActivityItem item) => '${item.title} ${item.detail}',
      emptyIcon: Icons.volunteer_activism_outlined,
      itemBuilder: (BuildContext context, ActivityItem item) => AppListTile(
        title: item.title,
        subtitle: item.detail,
        detail: '${AppStrings.completedSteps}: '
            '${UrduNumbers.ratio(item.completed, item.total)}',
        icon: item.icon,
        status: item.status,
        progress: item.progress,
        accentColor: AppColors.oliveGreen,
        onTap: () => context.push(
          AppRoutes.graduateActivityDetail,
          extra: item,
        ),
      ),
    );
  }
}
