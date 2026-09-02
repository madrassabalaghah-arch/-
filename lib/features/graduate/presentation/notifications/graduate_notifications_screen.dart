import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Notifications addressed to the graduate.
class GraduateNotificationsScreen extends ConsumerWidget {
  const GraduateNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<NotificationItem>(
      title: AppStrings.notifications,
      items: ref.watch(graduateNotificationsProvider),
      onRefresh: () => ref.refresh(graduateNotificationsProvider.future),
      showSearch: false,
      searchText: (NotificationItem item) => item.title,
      emptyIcon: Icons.notifications_none_outlined,
      itemBuilder: (BuildContext context, NotificationItem item) => AppListTile(
        title: item.title,
        subtitle: item.body,
        detail: item.timeLabel,
        icon: item.icon,
        accentColor:
            item.isUnread ? AppColors.primaryGreen : AppColors.gray,
        onTap: () {},
      ),
    );
  }
}
