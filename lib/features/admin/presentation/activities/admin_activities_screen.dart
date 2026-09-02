import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Administration of the shared activity catalogue.
///
/// This is the list every graduate chooses from when filing a کارگزاری, so it
/// is deliberately central: only an administrator may add to it, and the
/// `activities` policies enforce that regardless of what this screen offers.
class AdminActivitiesScreen extends ConsumerWidget {
  const AdminActivitiesScreen({super.key});

  static Future<void> _add(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController title = TextEditingController();
    final TextEditingController detail = TextEditingController();
    final TextEditingController steps = TextEditingController(text: '6');

    final bool saved = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.addActivity),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppFormField(
                    label: AppStrings.activityTitle,
                    controller: title,
                    isRequired: true,
                    prefixIcon: Icons.task_alt_outlined,
                  ),
                  AppSpacing.gapLg,
                  AppFormField(
                    label: AppStrings.activityDetail,
                    controller: detail,
                    maxLines: 3,
                  ),
                  AppSpacing.gapLg,
                  AppFormField(
                    label: AppStrings.activitySteps,
                    controller: steps,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.format_list_numbered,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.save),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved || title.text.trim().isEmpty) {
      title.dispose();
      detail.dispose();
      steps.dispose();
      return;
    }

    try {
      await ref.read(referenceRepositoryProvider).createActivity(
            title: title.text,
            detail: detail.text,
            totalSteps: int.tryParse(steps.text.trim()) ?? 1,
          );
      ref.invalidate(allActivitiesProvider);
      ref.invalidate(activityCatalogueProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.activityAdded)));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('${AppStrings.somethingWentWrong} — $error')),
        );
    } finally {
      title.dispose();
      detail.dispose();
      steps.dispose();
    }
  }

  /// Retires or restores an activity.
  ///
  /// Retiring rather than deleting matters: reports already filed against an
  /// activity keep their link, and a deleted row would break them. A retired
  /// activity simply stops being offered for new reports.
  static Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    ActivityItem item,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool activate = item.status != AppStatus.active;
    try {
      await ref.read(referenceRepositoryProvider).setActivityStatus(
            id: item.id,
            active: activate,
          );
      ref.invalidate(allActivitiesProvider);
      ref.invalidate(activityCatalogueProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(activate
              ? AppStrings.activityRestored
              : AppStrings.activityRetired),
        ));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('${AppStrings.somethingWentWrong} — $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<ActivityItem>(
      title: AppStrings.manageActivities,
      items: ref.watch(allActivitiesProvider),
      onRefresh: () => ref.refresh(allActivitiesProvider.future),
      searchText: (ActivityItem item) => '${item.title} ${item.detail ?? ''}',
      emptyIcon: Icons.volunteer_activism_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.addActivity,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _add(context, ref),
        ),
      ],
      itemBuilder: (BuildContext context, ActivityItem item) => AppListTile(
        title: item.title,
        subtitle: item.detail,
        detail:
            '${AppStrings.activitySteps}: ${UrduNumbers.fromInt(item.total)}',
        icon: item.icon,
        status: item.status,
        accentColor: item.status == AppStatus.active
            ? AppColors.oliveGreen
            : AppColors.gray,
        trailing: IconButton(
          tooltip: item.status == AppStatus.active
              ? AppStrings.retireActivity
              : AppStrings.restoreActivity,
          icon: Icon(
            item.status == AppStatus.active
                ? Icons.toggle_on
                : Icons.toggle_off_outlined,
            color: item.status == AppStatus.active
                ? AppColors.primaryGreen
                : AppColors.gray,
            size: 28,
          ),
          onPressed: () => _toggle(context, ref, item),
        ),
      ),
    );
  }
}
