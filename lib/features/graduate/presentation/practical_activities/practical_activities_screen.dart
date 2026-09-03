import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
        onTap: () => _showActivity(context, item),
      ),
    );
  }
}

/// Opens one activity's own detail view.
///
/// Everything shown is the activity's real stored record — its title, its
/// description and the graduate's counted progress against it. Nothing is
/// filled in when a field is empty; the row is simply left out.
Future<void> _showActivity(BuildContext context, ActivityItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      final ThemeData theme = Theme.of(context);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(item.icon, color: AppColors.oliveGreen),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(item.title, style: theme.textTheme.titleMedium),
                  ),
                  StatusBadge(status: item.status, compact: true),
                ],
              ),
              if (item.detail != null && item.detail!.trim().isNotEmpty) ...<Widget>[
                AppSpacing.gapLg,
                Text(item.detail!, style: theme.textTheme.bodyMedium),
              ],
              AppSpacing.gapLg,
              Text(
                '${AppStrings.completedSteps}: '
                '${UrduNumbers.ratio(item.completed, item.total)}',
                style: theme.textTheme.labelLarge,
              ),
              AppSpacing.gapSm,
              ClipRRect(
                borderRadius: AppRadius.radiusPill,
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.lightGray,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.oliveGreen),
                ),
              ),
              AppSpacing.gapXl,
              OutlinedButton(
                // Closes the sheet and nothing else, leaving the list exactly
                // where it was.
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
        ),
      );
    },
  );
}

