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
    final AsyncValue<AdminStatistics> statistics = ref.watch(
      adminStatisticsProvider,
    );
    final AsyncValue<List<NotificationItem>> notifications = ref.watch(
      adminNotificationsProvider,
    );

    final int unread =
        notifications.value?.where((NotificationItem n) => n.isUnread).length ??
        0;

    // Pulling down re-counts everything. The figures are a FutureProvider,
    // so without this they would keep showing what was true when the
    // dashboard was first opened.
    Future<void> refresh() async {
      ref.invalidate(adminStatisticsProvider);
      await ref.read(adminStatisticsProvider.future);
    }

    return AppScaffold(
      showAppBar: false,
      padBody: false,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
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
              onProfileTap: () => context.goToRoute(AppRoutes.adminProfile),
              onNotificationsTap: () =>
                  context.goToRoute(AppRoutes.adminNotifications),
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
                  AsyncSection<AdminStatistics>(
                    value: statistics,
                    onRetry: () => ref.invalidate(adminStatisticsProvider),
                    builder: (BuildContext context, AdminStatistics counts) =>
                        _Figures(counts: counts),
                  ),
                  AppSpacing.gapXl,
                  for (final ({String title, List<ManagementArea> areas}) group
                      in AppQuickActions.adminGroups) ...<Widget>[
                    SectionHeader(title: group.title),
                    _ManagementGrid(areas: group.areas),
                    AppSpacing.gapXl,
                  ],
                  AppSpacing.gapXl,
                  SectionHeader(
                    title: AppStrings.recentNotifications,
                    actionLabel: AppStrings.viewAll,
                    onAction: () =>
                        context.goToRoute(AppRoutes.adminNotifications),
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
                                for (final NotificationItem item in items.take(
                                  3,
                                ))
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
      ),
    );
  }
}

/// The figures, in three groups, because they answer three questions.
///
/// کل comes from the course register — everyone the organisation has on its
/// books, account or no account. فعال counts only the register records that
/// are linked to an account. The two are never added together, and neither
/// is ever inferred from the other.
class _Figures extends StatelessWidget {
  const _Figures({required this.counts});

  final AdminStatistics counts;

  static String _n(int value) => UrduNumbers.fromInt(value);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(AppStrings.countsExplained, style: theme.textTheme.labelSmall),
        AppSpacing.gapMd,
        const SectionHeader(title: AppStrings.registerSection),
        StatGrid(
          // فاضل before فاضلہ.
          stats: <StatItem>[
            StatItem(
              label: AppStrings.totalMale,
              value: _n(counts.totalMale),
              icon: Icons.school_outlined,
            ),
            StatItem(
              label: AppStrings.totalFemale,
              value: _n(counts.totalFemale),
              icon: Icons.school_outlined,
              tone: StatTone.teal,
            ),
            StatItem(
              label: AppStrings.totalBoth,
              value: _n(counts.totalGraduates),
              icon: Icons.groups_outlined,
              tone: StatTone.olive,
            ),
          ],
          // The register is where these were counted, so that is where
          // tapping one goes.
          onTap: (int _) => context.goToRoute(AppRoutes.adminWorkshop),
        ),
        // Shown only when there is something to reconcile, so the figures
        // never quietly disagree with each other.
        if (counts.totalUnrecordedGender > 0)
          _Note(
            text:
                '${AppStrings.genderNotRecorded}: '
                '${_n(counts.totalUnrecordedGender)}',
            tone: AppColors.warning,
          ),
        AppSpacing.gapXl,
        const SectionHeader(title: AppStrings.accountsSection),
        StatGrid(
          stats: <StatItem>[
            StatItem(
              label: AppStrings.activeMale,
              value: _n(counts.activeMale),
              icon: Icons.how_to_reg_outlined,
            ),
            StatItem(
              label: AppStrings.activeFemale,
              value: _n(counts.activeFemale),
              icon: Icons.how_to_reg_outlined,
              tone: StatTone.teal,
            ),
            StatItem(
              label: AppStrings.activeBoth,
              value: _n(counts.activeGraduates),
              icon: Icons.verified_user_outlined,
              tone: StatTone.olive,
            ),
            StatItem(
              label: AppStrings.totalMentors,
              value: _n(counts.mentors),
              icon: Icons.supervisor_account_outlined,
              tone: StatTone.gold,
            ),
          ],
          onTap: (int index) => context.goToRoute(
            index == 3 ? AppRoutes.adminMentors : AppRoutes.adminGraduates,
          ),
        ),
        if (counts.accountsWithoutRecord > 0)
          _Note(
            text:
                '${AppStrings.accountsWithoutRecord}: '
                '${_n(counts.accountsWithoutRecord)}',
            tone: AppColors.warning,
          ),
        AppSpacing.gapXl,
        const SectionHeader(title: AppStrings.allReports),
        StatGrid(
          stats: <StatItem>[
            StatItem(
              label: AppStrings.pendingReports,
              value: _n(counts.pendingReports),
              icon: Icons.pending_actions_outlined,
              tone: StatTone.brown,
            ),
            StatItem(
              label: AppStrings.underReview,
              value: _n(counts.underReview),
              icon: Icons.rate_review_outlined,
              tone: StatTone.gold,
            ),
            StatItem(
              label: AppStrings.lateSubmissions,
              value: _n(counts.lateReports),
              icon: Icons.schedule_outlined,
              tone: StatTone.neutral,
            ),
          ],
          onTap: (int _) => context.goToRoute(AppRoutes.adminReports),
        ),
      ],
    );
  }
}

/// A quiet line under a group of figures, for a number that needs an
/// explanation rather than a tile of its own.
class _Note extends StatelessWidget {
  const _Note({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: tone),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tone),
            ),
          ),
        ],
      ),
    );
  }
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
