import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_navigation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/constants/app_quick_actions.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/sign_out_action.dart';
import '../../../../shared/widgets/widgets.dart';

/// The administrator dashboard.
///
/// Uses the darker green brand surface, white data cards and gold highlights,
/// which is the same visual system as the other dashboards with a stronger
/// brand tone.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSession? session = ref.watch(appSessionProvider).value;
    final AppUser? profile = ref.watch(currentProfileProvider);
    final AsyncValue<Map<String, int>> statistics =
        ref.watch(adminStatisticsProvider);
    final AsyncValue<List<NotificationItem>> notifications =
        ref.watch(adminNotificationsProvider);

    final int unread =
        notifications.value?.where((NotificationItem n) => n.isUnread).length ??
            0;

    return AppScaffold(
      showAppBar: false,
      padBody: false,
      body: ListView(
        padding: const EdgeInsetsDirectional.only(
          bottom: AppSpacing.bottomSafeArea,
        ),
        children: <Widget>[
          AppHeader(
            name: session?.displayName ?? '',
            roleTitle: AppRole.admin.urduTitle,
            subtitle: profile?.instituteName,
            notificationCount: unread,
            gradient: AppGradients.darkGreen,
            actions: const <Widget>[SignOutAction()],
            onProfileTap: () => context.goToRoute(AppRoutes.adminGraduates),
            onNotificationsTap: () => context.goToRoute(AppRoutes.adminNotifications),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SectionHeader(title: AppStrings.systemOverview),
                AsyncSection<Map<String, int>>(
                  value: statistics,
                  onRetry: () => ref.invalidate(adminStatisticsProvider),
                  builder: (BuildContext context, Map<String, int> counts) =>
                      StatGrid(stats: _statsFrom(counts)),
                ),
                AppSpacing.gapXl,
                const SectionHeader(title: AppStrings.managementAreas),
                const _ManagementGrid(areas: AppQuickActions.adminAreas),
                AppSpacing.gapXl,
                SectionHeader(
                  title: AppStrings.recentNotifications,
                  actionLabel: AppStrings.viewAll,
                  onAction: () => context.goToRoute(AppRoutes.adminNotifications),
                ),
                AsyncSection<List<NotificationItem>>(
                  value: notifications,
                  isEmpty: (List<NotificationItem> n) => n.isEmpty,
                  emptyTitle: AppStrings.noNotificationsYet,
                  emptyIcon: Icons.notifications_none_outlined,
                  onRetry: () => ref.invalidate(adminNotificationsProvider),
                  builder:
                      (BuildContext context, List<NotificationItem> items) =>
                          Column(
                    children: <Widget>[
                      for (final NotificationItem item in items.take(3))
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: AppSpacing.md,
                          ),
                          child: AppListTile(
                            title: item.title,
                            subtitle: item.body,
                            detail: item.timeLabel,
                            icon: item.icon,
                            accentColor: item.isUnread
                                ? AppColors.darkGreen
                                : AppColors.gray,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns the counted rows into statistic tiles. Every figure is a real
/// count from Postgres; nothing here is stored or hardcoded.
List<StatItem> _statsFrom(Map<String, int> counts) {
  String n(String key) => UrduNumbers.fromInt(counts[key] ?? 0);

  return <StatItem>[
    StatItem(
      label: AppStrings.totalGraduates,
      value: n('graduates'),
      icon: Icons.school_outlined,
    ),
    StatItem(
      label: AppStrings.activeGraduates,
      value: n('activeGraduates'),
      icon: Icons.how_to_reg_outlined,
      tone: StatTone.teal,
    ),
    StatItem(
      label: AppStrings.totalMentors,
      value: n('mentorAssignments'),
      icon: Icons.supervisor_account_outlined,
      tone: StatTone.olive,
    ),
    StatItem(
      label: AppStrings.pendingReports,
      value: n('pendingReports'),
      icon: Icons.pending_actions_outlined,
      tone: StatTone.brown,
    ),
    StatItem(
      label: AppStrings.underReview,
      value: n('underReview'),
      icon: Icons.rate_review_outlined,
      tone: StatTone.gold,
    ),
    StatItem(
      label: AppStrings.lateSubmissions,
      value: n('lateReports'),
      icon: Icons.schedule_outlined,
      tone: StatTone.neutral,
    ),
  ];
}

/// The management areas, laid out as a responsive grid of information cards.
class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({required this.areas});

  final List<ManagementArea> areas;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: areas.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.wideGridColumns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 108,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ManagementArea area = areas[index];

        return DashboardCard(
          variant: DashboardCardVariant.info,
          accentColor: AppColors.darkGreen,
          onTap: () => context.goToRoute(area.route),
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.darkGreen.withValues(alpha: 0.10),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(area.icon, size: 22, color: AppColors.darkGreen),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      area.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      area.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
