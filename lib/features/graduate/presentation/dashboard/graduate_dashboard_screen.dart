import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/sign_out_action.dart';

/// The graduate dashboard, laid out most important first: who the reader is
/// and their standing, the one action they come to take, what they have done,
/// where to go next, what happened recently, and what is waiting for them.
///
/// Each destination has one entry point. A summary card opens its list, a
/// category opens its filtered list, and nothing is reachable twice.
class GraduateDashboardScreen extends ConsumerWidget {
  const GraduateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSession? session = ref.watch(appSessionProvider).value;
    final AsyncValue<List<NotificationItem>> notifications =
        ref.watch(graduateNotificationsProvider);
    final int unread =
        notifications.value?.where((NotificationItem n) => n.isUnread).length ??
            0;

    return AppScaffold(
      showAppBar: false,
      padBody: false,
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          ref.invalidate(graduateActivitiesProvider);
          ref.invalidate(graduateTasksProvider);
          ref.invalidate(graduateMentorFeedbackProvider);
          ref.invalidate(followUpStatusProvider);
          ref.invalidate(reportCategoriesProvider);
          await ref.read(appSessionProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            // 1 and 2: the reader, and their standing as a graduate in the
            // practical field rather than a trainee.
            AppHeader(
              name: session?.displayName ?? '',
              roleTitle: AppRole.graduate.urduTitle,
              subtitle: AppStrings.graduateStatus,
              notificationCount: unread,
              onProfileTap: () => context.goToRoute(AppRoutes.graduateProfile),
              actions: const <Widget>[SignOutAction()],
              onNotificationsTap: () =>
                  context.goToRoute(AppRoutes.graduateNotifications),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 3: the existing کارگزاری editor; there is no second one.
                  PrimaryButton(
                    label: AppStrings.newKarGuzari,
                    onPressed: () =>
                        context.goToRoute(AppRoutes.graduateReportEditor),
                  ),
                  AppSpacing.gapXl,
                  // 4: the shared کمیونٹی بورڈ, open to every role.
                  DashboardCard(
                    variant: DashboardCardVariant.info,
                    accentColor: AppColors.oliveGreen,
                    onTap: () => context.goToRoute(AppRoutes.communityBoard),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.forum_outlined,
                            color: AppColors.oliveGreen),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(AppStrings.communityBoard,
                                  style: Theme.of(context).textTheme.titleSmall),
                              AppSpacing.gapXxs,
                              Text(AppStrings.communityBoardSubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXl,
                  // 5
                  const SectionHeader(title: AppStrings.quickActions),
                  const _QuickAccess(),
                  AppSpacing.gapXl,
                  // 6
                  const SectionHeader(title: AppStrings.recentActivity),
                  AsyncSection<JourneyProgress>(
                    value: ref.watch(graduateJourneyProvider),
                    onRetry: () => ref.invalidate(graduateJourneyProvider),
                    builder: (BuildContext context, JourneyProgress journey) =>
                        InkWell(
                      borderRadius: AppRadius.radiusLg,
                      // The journey is made of practical activities, so it
                      // opens them, and each opens its own detail.
                      onTap: () =>
                          context.goToRoute(AppRoutes.graduateActivities),
                      child: ProgressCard(journey: journey),
                    ),
                  ),
                  AppSpacing.gapLg,
                  AsyncSection<FollowUpStatus?>(
                    value: ref.watch(followUpStatusProvider),
                    isEmpty: (FollowUpStatus? f) => f == null,
                    emptyTitle: AppStrings.followUpNone,
                    emptyIcon: Icons.event_repeat_outlined,
                    onRetry: () => ref.invalidate(followUpStatusProvider),
                    builder: (BuildContext context, FollowUpStatus? status) =>
                        _FollowUpCard(status: status!),
                  ),
                  AppSpacing.gapXl,
                  SectionHeader(
                    title: AppStrings.mentorGuidance,
                    actionLabel: AppStrings.viewAll,
                    onAction: () =>
                        context.goToRoute(AppRoutes.graduateEvaluations),
                  ),
                  AsyncSection<MentorFeedback?>(
                    value: ref.watch(graduateMentorFeedbackProvider),
                    isEmpty: (MentorFeedback? f) => f == null,
                    emptyTitle: AppStrings.noGuidanceYet,
                    emptyIcon: Icons.record_voice_over_outlined,
                    onRetry: () =>
                        ref.invalidate(graduateMentorFeedbackProvider),
                    builder: (BuildContext context, MentorFeedback? feedback) =>
                        MentorFeedbackCard(feedback: feedback!),
                  ),
                  AppSpacing.gapXl,
                  SectionHeader(
                    title: AppStrings.recognitionSection,
                    isGold: true,
                    actionLabel: AppStrings.viewAll,
                    onAction: () =>
                        context.goToRoute(AppRoutes.graduateRecognition),
                  ),
                  AsyncSection<List<RecognitionItem>>(
                    value: ref.watch(graduateRecognitionsProvider),
                    isEmpty: (List<RecognitionItem> r) => r.isEmpty,
                    emptyTitle: AppStrings.noRecognitionsYet,
                    emptyIcon: Icons.workspace_premium_outlined,
                    builder:
                        (BuildContext context, List<RecognitionItem> items) =>
                            Column(
                      children: <Widget>[
                        for (final RecognitionItem item in items.take(2))
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: AppSpacing.md,
                            ),
                            child: RecognitionCard(item: item),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXl,
                  // 7
                  const SectionHeader(title: AppStrings.pendingItems),
                  AsyncSection<List<TaskItem>>(
                    value: ref.watch(graduateTasksProvider),
                    isEmpty: (List<TaskItem> t) => t.isEmpty,
                    emptyTitle: AppStrings.emptyNoPending,
                    emptyIcon: Icons.task_alt_outlined,
                    onRetry: () => ref.invalidate(graduateTasksProvider),
                    builder: (BuildContext context, List<TaskItem> tasks) =>
                        Column(
                      children: <Widget>[
                        for (final TaskItem task in tasks)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: AppSpacing.md,
                            ),
                            child: AppListTile(
                              title: task.title,
                              subtitle: task.detail,
                              detail: task.dueLabel,
                              icon: task.icon,
                              status: task.status,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXl,
                  SectionHeader(
                    title: AppStrings.recentNotifications,
                    actionLabel: AppStrings.viewAll,
                    onAction: () =>
                        context.goToRoute(AppRoutes.graduateNotifications),
                  ),
                  AsyncSection<List<NotificationItem>>(
                    value: notifications,
                    isEmpty: (List<NotificationItem> n) => n.isEmpty,
                    emptyTitle: AppStrings.emptyNoNotifications,
                    emptyIcon: Icons.notifications_none_outlined,
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
                                  ? AppColors.primaryGreen
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

/// The three figures the brief asks for. Each opens exactly the list it
/// evidence is grouped by the file kind `evidence.kind` records.
class _QuickAccess extends ConsumerWidget {
  const _QuickAccess();

  static const List<(String, String, IconData)> _evidenceKinds =
      <(String, String, IconData)>[
    ('image', AppStrings.evidenceImages, Icons.image_outlined),
    ('document', AppStrings.evidenceDocuments, Icons.description_outlined),
    ('video', AppStrings.evidenceOther, Icons.attach_file_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncSection<List<ReportCategory>>(
      value: ref.watch(reportCategoriesProvider),
      onRetry: () => ref.invalidate(reportCategoriesProvider),
      builder: (BuildContext context, List<ReportCategory> categories) {
        final Map<String, List<ReportCategory>> groups =
            <String, List<ReportCategory>>{};
        for (final ReportCategory c in categories) {
          groups.putIfAbsent(c.groupKey, () => <ReportCategory>[]).add(c);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final List<ReportCategory> group in groups.values) ...<Widget>[
              _QuickAccessGroup(
                title: group.first.groupTitle,
                tiles: <Widget>[
                  for (final ReportCategory c in group)
                    _QuickTile(
                      label: c.title,
                      icon: c.icon,
                      onTap: () => context.goToRoute(
                        AppRoutes.graduateReports,
                        extra: (
                          filter: KarGuzariFilter.all,
                          categoryKey: c.key,
                          title: c.title,
                        ),
                      ),
                    ),
                ],
              ),
              AppSpacing.gapMd,
            ],
            _QuickAccessGroup(
              title: AppStrings.evidenceGroup,
              tiles: <Widget>[
                for (final (String, String, IconData) k in _evidenceKinds)
                  _QuickTile(
                    label: k.$2,
                    icon: k.$3,
                    onTap: () => context.goToRoute(
                      AppRoutes.graduateEvidence,
                      extra: (kind: k.$1, title: k.$2),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// One heading of quick access and the destinations beneath it.
class _QuickAccessGroup extends StatelessWidget {
  const _QuickAccessGroup({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tiles,
          ),
        ],
      ),
    );
  }
}

/// A single quick access destination.
class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greenTint,
      borderRadius: AppRadius.radiusPill,
      child: InkWell(
        borderRadius: AppRadius.radiusPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: AppColors.primaryGreen),
              AppSpacing.hGapXs,
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.primaryGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the reader stands in the follow-up cycle, computed by the database
/// from the configured interval.
class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.status});

  final FollowUpStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool warn = status.isOverdue || status.isDueSoon;
    final Color accent = warn ? AppColors.warning : AppColors.primaryGreen;

    return DashboardCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                status.isOverdue
                    ? Icons.error_outline
                    : Icons.event_available_outlined,
                color: accent,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  status.isOverdue
                      ? AppStrings.followUpOverdue
                      : AppStrings.followUpTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (status.dueOn != null) ...<Widget>[
            AppSpacing.gapMd,
            Text(
              UrduDates.label(status.dueOn),
              style: theme.textTheme.titleMedium?.copyWith(color: accent),
            ),
          ],
          AppSpacing.gapSm,
          Text(
            status.isOverdue
                ? '${AppStrings.followUpSubmitted}: '
                    '${UrduNumbers.fromInt(status.submittedCount)}'
                : '${AppStrings.followUpDaysLeft}: '
                    '${UrduNumbers.fromInt(status.daysRemaining)} '
                    '${AppStrings.daysUnit}   •   '
                    '${AppStrings.followUpSubmitted}: '
                    '${UrduNumbers.fromInt(status.submittedCount)}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
