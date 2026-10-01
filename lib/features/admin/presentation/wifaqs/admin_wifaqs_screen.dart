import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Administration of the examination boards and their institutes.
class AdminWifaqsScreen extends ConsumerWidget {
  const AdminWifaqsScreen({super.key});

  /// Adds a wifaq from a small dialog. Users pick from this list and cannot
  /// add to it, so this is the only place new boards appear.
  static Future<void> _addWifaq(BuildContext context, WidgetRef ref) async {
    // Captured before the dialog, so it is never read from a context that
    // may have been disposed while the dialog was open.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController name = TextEditingController();
    final TextEditingController city = TextEditingController();

    final bool saved = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.addWifaq),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppFormField(
                  label: AppStrings.wifaqName,
                  controller: name,
                  isRequired: true,
                  prefixIcon: Icons.account_balance_outlined,
                ),
                AppSpacing.gapLg,
                AppFormField(
                  label: AppStrings.cityOptional,
                  controller: city,
                  prefixIcon: Icons.location_city_outlined,
                ),
              ],
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

    if (!saved || name.text.trim().isEmpty) {
      name.dispose();
      city.dispose();
      return;
    }

    try {
      await ref
          .read(adminRepositoryProvider)
          .createWifaq(name: name.text, city: city.text);
      ref.invalidate(adminWifaqsProvider);
      ref.invalidate(adminWifaqDirectoryProvider);
      ref.invalidate(wifaqListProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.wifaqAdded)));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
            content: Text('${AppStrings.somethingWentWrong} — $error')));
    } finally {
      name.dispose();
      city.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<WifaqDirectoryEntry>(
      title: AppStrings.wifaqs,
      items: ref.watch(adminWifaqDirectoryProvider),
      onRefresh: () => ref.refresh(adminWifaqDirectoryProvider.future),
      searchText: (WifaqDirectoryEntry item) =>
          '${item.displayName} ${item.city ?? ""}',
      emptyIcon: Icons.account_balance_outlined,
      emptyTitle: AppStrings.noRecordsYet,
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.addWifaq,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _addWifaq(context, ref),
        ),
      ],
      itemBuilder: (BuildContext context, WifaqDirectoryEntry item) =>
          AppListTile(
        title: item.displayName,
        subtitle:
            '${AppStrings.malePlural} ${UrduNumbers.fromInt(item.maleCount)}'
            '   ${AppStrings.femalePlural} ${UrduNumbers.fromInt(item.femaleCount)}',
        detail: '${AppStrings.institutes}: '
            '${UrduNumbers.fromInt(item.instituteCount)}   •   '
            '${AppStrings.totalGraduates}: '
            '${UrduNumbers.fromInt(item.graduateTotal)}',
        icon: Icons.account_balance_outlined,
        status: item.isUnassigned ? null : item.status,
        accentColor: item.isUnassigned ? AppColors.gray : AppColors.earthBrown,
        onTap: () => context.push(
          AppRoutes.adminWifaqInstitutes,
          extra: item,
        ),
      ),
    );
  }
}
