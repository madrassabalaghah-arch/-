import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The evaluation standards and the weight carried by each one.
class AdminStandardsScreen extends ConsumerWidget {
  const AdminStandardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<StandardItem>(
      title: AppStrings.standards,
      items: ref.watch(adminStandardsProvider),
      onRefresh: () => ref.refresh(adminStandardsProvider.future),
      showSearch: false,
      searchText: (StandardItem item) => item.title,
      emptyIcon: Icons.rule_outlined,
      itemBuilder: (BuildContext context, StandardItem item) => AppListTile(
        title: item.title,
        subtitle: item.detail,
        icon: Icons.rule_outlined,
        status: item.status,
        progress: item.weight / 100,
        accentColor: AppColors.gold,
        trailing: Text(
          UrduNumbers.percent(item.weight),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.earthBrown,
              ),
        ),
      ),
    );
  }
}
