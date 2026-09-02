import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_quick_actions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/sign_out_action.dart';

/// The graduate dashboard.
///
/// Every figure and row comes from Supabase through the providers. Sections
/// resolve independently, so one slow query never blanks the page.
class GraduateDashboardScreen extends ConsumerWidget {
  const GraduateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSession? session = ref.watch(appSessionProvider).value;
    final AppUser? profile = ref.watch(currentProfileProvider);
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
          ref.invalidate(graduateFollowUpProvider);
          await ref.read(appSessionProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            AppHeader(
              name: session?.displayName ?? '',
              roleTitle: AppRole.graduate.urduTitle,
              subtitle: profile?.stage,
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
                  AsyncSection<JourneyProgress>(
                    value: ref.watch(graduateJourneyProvider),
                    onRetry: () => ref.invalidate(graduateJourneyProvider),
                    builder: (BuildContext context, JourneyProgress journey) =>
                        ProgressCard(journey: journey),
                  ),
                  AppSpacing.gapXl,
                  SectionHeader(
                    title: AppStrings.pendingTasks,
                    actionLabel: AppStrings.viewAll,
                    onAction: () =>
                        context.goToRoute(AppRoutes.graduateReports),
                  ),
                  AsyncSection<List<TaskItem>>(
                    value: ref.watch(graduateTasksProvider),
                    isEmpty: (List<TaskItem> t) => t.isEmpty,
                    emptyTitle: AppStrings.noPendingTasks,
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
                  AppSpacing.gapMd,
                  const SectionHeader(title: AppStrings.quickActions),
                  const QuickActionGrid(actions: AppQuickActions.graduate),
                  AppSpacing.gapXl,
                  const SectionHeader(title: AppStrings.mentorGuidance),
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
                  AppSpacing.gapMd,
                  const SectionHeader(title: AppStrings.followUp),
                  AsyncSection<FollowUpItem?>(
                    value: ref.watch(graduateFollowUpProvider),
                    isEmpty: (FollowUpItem? f) => f == null,
                    emptyTitle: AppStrings.noFollowUpYet,
                    emptyIcon: Icons.event_repeat_outlined,
                    onRetry: () => ref.invalidate(graduateFollowUpProvider),
                    builder: (BuildContext context, FollowUpItem? followUp) =>
                        AppListTile(
                      title: followUp!.title,
                      subtitle: followUp.detail,
                      detail: followUp.dateLabel,
                      icon: Icons.event_repeat_outlined,
                      status: followUp.status,
                      accentColor: AppColors.tealGreen,
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
                    emptyTitle: AppStrings.noNotificationsYet,
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
