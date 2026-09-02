import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Administration of the training courses.
class AdminCoursesScreen extends ConsumerWidget {
  const AdminCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<CourseItem>(
      title: AppStrings.courses,
      items: ref.watch(adminCoursesProvider),
      onRefresh: () => ref.refresh(adminCoursesProvider.future),
      searchText: (CourseItem item) => item.title,
      emptyIcon: Icons.menu_book_outlined,
      itemBuilder: (BuildContext context, CourseItem item) => AppListTile(
        title: item.title,
        subtitle: item.durationLabel,
        detail: item.durationLabel,
        icon: Icons.menu_book_outlined,
        status: item.status,
        accentColor: AppColors.tealGreen,
        onTap: () {},
      ),
    );
  }
}
