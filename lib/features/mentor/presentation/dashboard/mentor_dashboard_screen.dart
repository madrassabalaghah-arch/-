import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_quick_actions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/presentation/sign_out_action.dart';

/// The mentor dashboard.
///
/// Only graduates actually assigned to this mentor appear here, and every
/// figure is counted from those same rows rather than stored anywhere.
class MentorDashboardScreen extends ConsumerWidget {
  const MentorDashboardScreen({super.key});

  /// Builds the statistic tiles from the real rows the mentor can see.
  static List<StatItem> statsFrom(
    List<GraduateSummary> graduates,
    List<ReportItem> reports,
    List<EvaluationItem> evaluations,
  ) {
    int countWhere(AppStatus status) =>
        reports.where((ReportItem r) => r.status == status).length;

    return <StatItem>[
      StatItem(
        label: AppStrings.myGraduates,
        value: UrduNumbers.fromInt(graduates.length),
        icon: Icons.groups_outlined,
      ),
      StatItem(
        label: AppStrings.newReports,
        value: UrduNumbers.fromInt(countWhere(AppStatus.submitted)),
        icon: Icons.mark_email_unread_outlined,
        tone: StatTone.teal,
      ),
      StatItem(
        label: AppStrings.awaitingReview,
        value: UrduNumbers.fromInt(countWhere(AppStatus.pending)),
        icon: Icons.hourglass_empty_outlined,
        tone: StatTone.brown,
      ),
      StatItem(
        label: AppStrings.underReview,
        value: UrduNumbers.fromInt(countWhere(AppStatus.underReview)),
        icon: Icons.rate_review_outlined,
        tone: StatTone.olive,
      ),
      StatItem(
        label: AppStrings.completedReviews,
        value: UrduNumbers.fromInt(evaluations.length),
        icon: Icons.fact_check_outlined,
        tone: StatTone.gold,
      ),
      StatItem(
        label: AppStrings.lateSubmissions,
        value: UrduNumbers.fromInt(countWhere(AppStatus.late)),
        icon: Icons.schedule_outlined,
        tone: StatTone.neutral,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSession? session = ref.watch(appSessionProvider).value;
    final AppUser? profile = ref.watch(currentProfileProvider);
    final AsyncValue<List<GraduateSummary>> graduates =
        ref.watch(mentorGraduatesProvider);
    final AsyncValue<List<ReportItem>> reports =
        ref.watch(mentorReportsProvider);
    final AsyncValue<List<EvaluationItem>> evaluations =
        ref.watch(mentorEvaluationsProvider);
    final AsyncValue<List<NotificationItem>> notifications =
        ref.watch(mentorNotificationsProvider);

    final int unread =
        notifications.value?.where((NotificationItem n) => n.isUnread).length ??
            0;

    return AppScaffold(
      showAppBar: false,
      padBody: false,
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          ref.invalidate(mentorGraduatesProvider);
          ref.invalidate(mentorReportsProvider);
          ref.invalidate(mentorEvaluationsProvider);
          ref.invalidate(mentorNotificationsProvider);
        },
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            AppHeader(
              name: session?.displayName ?? '',
              roleTitle: AppRole.mentor.urduTitle,
              subtitle: profile?.instituteName,
              notificationCount: unread,
              onProfileTap: () => context.goToRoute(AppRoutes.mentorGraduates),
              actions: const <Widget>[SignOutAction()],
              onNotificationsTap: () =>
                  context.goToRoute(AppRoutes.mentorReviews),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: _MentorBody(
                graduates: graduates,
                reports: reports,
                evaluations: evaluations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scrolling content of the mentor dashboard.
class _MentorBody extends ConsumerWidget {
  const _MentorBody({
    required this.graduates,
    required this.reports,
    required this.evaluations,
  });

  final AsyncValue<List<GraduateSummary>> graduates;
  final AsyncValue<List<ReportItem>> reports;
  final AsyncValue<List<EvaluationItem>> evaluations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(title: AppStrings.systemOverview),
        if (graduates.hasValue && reports.hasValue && evaluations.hasValue)
          StatGrid(
            stats: MentorDashboardScreen.statsFrom(
              graduates.value!,
              reports.value!,
              evaluations.value!,
            ),
          )
        else if (graduates.hasError || reports.hasError)
          const DashboardCard(child: ErrorState(compact: true))
        else
          const DashboardCard(child: LoadingState(compact: true)),
        AppSpacing.gapXl,
        const SectionHeader(title: AppStrings.quickActions),
        const QuickActionGrid(actions: AppQuickActions.mentor),
        AppSpacing.gapXl,
        SectionHeader(
          title: AppStrings.recentGraduates,
          actionLabel: AppStrings.viewAll,
          onAction: () => context.goToRoute(AppRoutes.mentorGraduates),
        ),
        AsyncSection<List<GraduateSummary>>(
          value: graduates,
          isEmpty: (List<GraduateSummary> g) => g.isEmpty,
          emptyTitle: AppStrings.noGraduatesYet,
          emptyIcon: Icons.groups_outlined,
          onRetry: () => ref.invalidate(mentorGraduatesProvider),
          builder: (BuildContext context, List<GraduateSummary> items) =>
              Column(
            children: <Widget>[
              for (final GraduateSummary graduate in items.take(4))
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                  child: AppListTile(
                    title: graduate.name,
                    subtitle: graduate.placeLine,
                    detail: graduate.stage,
                    avatarText: graduate.avatarLabel,
                    status: graduate.status,
                    progress: graduate.progress,
                    onTap: () =>
                        context.goToRoute(AppRoutes.mentorGraduateDetails),
                  ),
                ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        SectionHeader(
          title: AppStrings.newReports,
          actionLabel: AppStrings.viewAll,
          onAction: () => context.goToRoute(AppRoutes.mentorReviews),
        ),
        AsyncSection<List<ReportItem>>(
          value: reports,
          isEmpty: (List<ReportItem> r) => r.isEmpty,
          emptyTitle: AppStrings.noReportsYet,
          emptyIcon: Icons.description_outlined,
          onRetry: () => ref.invalidate(mentorReportsProvider),
          builder: (BuildContext context, List<ReportItem> items) => Column(
            children: <Widget>[
              for (final ReportItem report in items.take(3))
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                  child: AppListTile(
                    title: report.title,
                    subtitle: report.graduateName,
                    detail: report.dateLabel,
                    icon: Icons.description_outlined,
                    status: report.status,
                    accentColor: AppColors.tealGreen,
                    onTap: () =>
                        context.goToRoute(AppRoutes.mentorReportDetails),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
