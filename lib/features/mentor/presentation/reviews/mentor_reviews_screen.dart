import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_navigation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Reports waiting for this mentor to review.
class MentorReviewsScreen extends ConsumerWidget {
  const MentorReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<ReportItem>(
      title: AppStrings.pendingReviews,
      items: ref.watch(mentorReportsProvider),
      onRefresh: () => ref.refresh(mentorReportsProvider.future),
      searchHint: AppStrings.hintSearchReport,
      searchText: (ReportItem item) =>
          '${item.title} ${item.graduateName ?? ''}',
      emptyIcon: Icons.rate_review_outlined,
      itemBuilder: (BuildContext context, ReportItem item) => AppListTile(
        title: item.title,
        subtitle: '${AppStrings.graduateName}: ${item.graduateLine}',
        detail: '${item.activityType} • ${item.dateLabel}',
        icon: Icons.description_outlined,
        status: item.status,
        accentColor: AppColors.tealGreen,
        onTap: () => context.goToRoute(AppRoutes.mentorReportDetails,
            extra: item),
        trailing: TextButton(
          onPressed: () =>
              context.goToRoute(AppRoutes.mentorReportReview, extra: item),
          child: const Text(AppStrings.review),
        ),
      ),
    );
  }
}
