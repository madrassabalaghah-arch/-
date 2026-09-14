import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/activities/admin_activities_screen.dart';
import '../../features/admin/presentation/assignments/admin_assignments_screen.dart';
import '../../features/admin/presentation/courses/admin_courses_screen.dart';
import '../../features/admin/presentation/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/presentation/evidence/admin_evidence_screen.dart';
import '../../features/admin/presentation/graduates/admin_graduates_screen.dart';
import '../../features/admin/presentation/mentors/admin_mentors_screen.dart';
import '../../features/admin/presentation/notifications/admin_notifications_screen.dart';
import '../../features/admin/presentation/overview/admin_overview_screens.dart';
import '../../features/admin/presentation/recognition/admin_recognition_screen.dart';
import '../../features/admin/presentation/reports/admin_report_detail_screen.dart';
import '../../features/admin/presentation/reports/admin_reports_screen.dart';
import '../../features/admin/presentation/settings/admin_settings_screen.dart';
import '../../features/admin/presentation/standards/admin_standards_screen.dart';
import '../../features/admin/presentation/users/admin_user_screen.dart';
import '../../features/admin/presentation/wifaqs/admin_wifaq_graduates_screen.dart';
import '../../features/admin/presentation/wifaqs/admin_wifaq_institutes_screen.dart';
import '../../features/admin/presentation/wifaqs/admin_wifaqs_screen.dart';
import '../../features/admin/presentation/workshop/admin_participants_screen.dart';
import '../../features/graduate/presentation/dashboard/graduate_dashboard_screen.dart';
import '../../features/graduate/presentation/evaluations/graduate_evaluations_screen.dart';
import '../../features/graduate/presentation/evidence/graduate_evidence_screen.dart';
import '../../features/graduate/presentation/notifications/graduate_notifications_screen.dart';
import '../../features/graduate/presentation/performance_reports/graduate_reports_screen.dart';
import '../../features/graduate/presentation/practical_activities/activity_detail_screen.dart';
import '../../features/graduate/presentation/practical_activities/practical_activities_screen.dart';
import '../../features/graduate/presentation/profile/graduate_profile_screen.dart';
import '../../features/graduate/presentation/recognition/graduate_recognition_screen.dart';
import '../../features/graduate/presentation/report_editor/report_editor_screen.dart';
import '../../features/mentor/presentation/dashboard/mentor_dashboard_screen.dart';
import '../../features/mentor/presentation/evaluations/mentor_evaluations_screen.dart';
import '../../features/mentor/presentation/evidence/mentor_evidence_screen.dart';
import '../../features/mentor/presentation/graduates/mentor_graduate_details_screen.dart';
import '../../features/mentor/presentation/graduates/mentor_graduates_screen.dart';
import '../../features/mentor/presentation/reports/mentor_report_details_screen.dart';
import '../../features/mentor/presentation/reviews/mentor_report_review_screen.dart';
import '../../features/mentor/presentation/reviews/mentor_reviews_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/no_role_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import '../../shared/models/app_role.dart';
import '../../shared/presentation/important_links_screen.dart';
import '../../shared/models/directory_entries.dart';
import '../../shared/models/people.dart';
import '../../shared/models/work_items.dart';
import '../../shared/providers/data_providers.dart';
import '../constants/app_strings.dart';
import '../../shared/widgets/error_state.dart';
import 'app_nav_items.dart';
import 'app_routes.dart';
import 'role_shell.dart';

/// The application router.
///
/// Route protection lives here rather than in each screen: the redirect below
/// is the single gate every navigation passes through, so a screen can never
/// be reached by deep link without a session and a role.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: false,

    // Re-evaluate the redirect whenever the session changes, so signing out
    // anywhere immediately bounces the user back to the sign in screen.
    refreshListenable: _SessionRefresh(ref),

    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<AppSession?> session = ref.read(appSessionProvider);

      // While the session is still resolving, hold position. Redirecting on
      // an unknown state would flash the sign in screen on every cold start.
      if (session.isLoading) {
        return null;
      }

      // A failed load is not a sign-out. When Supabase still holds the
      // persisted session the account is signed in and merely offline, so
      // hold position and let the screen show its own error state rather
      // than bouncing the user to sign in and losing their place.
      if (session.hasError &&
          ref.read(authRepositoryProvider).currentUser != null) {
        return null;
      }

      final AppSession? current = session.value;
      final String location = state.matchedLocation;
      final bool isPublic = AppRoutes.publicRoutes.contains(location);

      // Signed out: everything except the public routes goes to sign in.
      if (current == null) {
        return isPublic ? null : AppRoutes.signIn;
      }

      // Signed in but no role granted yet.
      final AppRole? role = current.primaryRole;
      if (role == null) {
        return location == AppRoutes.noRole ? null : AppRoutes.noRole;
      }

      final String home = homeFor(role);

      // Signed in with a role: the public routes and the no-role holding
      // screen are no longer meaningful, so send them home.
      if (isPublic || location == AppRoutes.noRole) {
        return home;
      }

      // Enforce role boundaries on the area prefixes themselves, so a
      // graduate cannot reach /admin by typing it. Row level security is the
      // real guard; this only keeps the UI honest.
      if (location.startsWith('/admin/') && role != AppRole.admin) {
        return home;
      }
      if (location.startsWith('/mentor/') && role != AppRole.mentor) {
        return home;
      }
      if (location.startsWith('/graduate/') && role != AppRole.graduate) {
        return home;
      }

      return null;
    },

    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: ErrorState(
        message: AppStrings.errorDetail,
        onRetry: () => context.go(AppRoutes.welcome),
      ),
    ),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRoutes.welcomeName,
        builder: (BuildContext context, GoRouterState state) =>
            const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        name: AppRoutes.signInName,
        builder: (BuildContext context, GoRouterState state) =>
            const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: AppRoutes.signUpName,
        builder: (BuildContext context, GoRouterState state) =>
            const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.noRole,
        name: AppRoutes.noRoleName,
        builder: (BuildContext context, GoRouterState state) =>
            const NoRoleScreen(),
      ),
      _graduateShell,
      _mentorShell,
      _adminShell,
      ..._graduateFullScreenRoutes,
      ..._mentorFullScreenRoutes,
      ..._adminFullScreenRoutes,
    ],
  );
});

/// Landing route for a role.
String homeFor(AppRole role) {
  switch (role) {
    case AppRole.graduate:
      return AppRoutes.graduateDashboard;
    case AppRole.mentor:
      return AppRoutes.mentorDashboard;
    case AppRole.admin:
      return AppRoutes.adminDashboard;
  }
}

/// Bridges the Riverpod session into something GoRouter can listen to.
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(this._ref) {
    _subscription = _ref.listen<AsyncValue<AppSession?>>(
      appSessionProvider,
      (AsyncValue<AppSession?>? previous, AsyncValue<AppSession?> next) {
        notifyListeners();
      },
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AppSession?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Graduate
// ---------------------------------------------------------------------------

/// The graduate bottom navigation branches.
final StatefulShellRoute _graduateShell = StatefulShellRoute.indexedStack(
  builder: (
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) =>
      RoleShell(navigationShell: navigationShell, items: AppNavItems.graduate),
  branches: <StatefulShellBranch>[
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.graduateDashboard,
          name: AppRoutes.graduateDashboardName,
          builder: (BuildContext context, GoRouterState state) =>
              const GraduateDashboardScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.graduateNotifications,
          name: AppRoutes.graduateNotificationsName,
          builder: (BuildContext context, GoRouterState state) =>
              const GraduateNotificationsScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.graduateProfile,
          name: AppRoutes.graduateProfileName,
          builder: (BuildContext context, GoRouterState state) =>
              const GraduateProfileScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.graduateLinks,
          name: AppRoutes.graduateLinksName,
          builder: (BuildContext context, GoRouterState state) =>
              const ImportantLinksScreen(),
        ),
      ],
    ),
  ],
);

/// Graduate screens that cover the bottom navigation.
final List<RouteBase> _graduateFullScreenRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.graduateReports,
    name: AppRoutes.graduateReportsName,
    builder: (BuildContext context, GoRouterState state) {
      final Object? extra = state.extra;
      if (extra is ({
        KarGuzariFilter filter,
        String? categoryKey,
        String title
      })) {
        return GraduateReportsScreen(
          filter: extra.filter,
          categoryKey: extra.categoryKey,
          title: extra.title,
        );
      }
      return const GraduateReportsScreen();
    },
  ),
  GoRoute(
    path: AppRoutes.graduateEvidence,
    name: AppRoutes.graduateEvidenceName,
    builder: (BuildContext context, GoRouterState state) {
      final Object? extra = state.extra;
      return extra is ({String kind, String title})
          ? GraduateEvidenceScreen(kind: extra.kind, title: extra.title)
          : const GraduateEvidenceScreen();
    },
  ),
  GoRoute(
    path: AppRoutes.graduateActivityDetail,
    name: AppRoutes.graduateActivityDetailName,
    builder: (BuildContext context, GoRouterState state) =>
        ActivityDetailScreen(activity: state.extra! as ActivityItem),
  ),
  GoRoute(
    path: AppRoutes.graduateReportEditor,
    name: AppRoutes.graduateReportEditorName,
    builder: (BuildContext context, GoRouterState state) =>
        ReportEditorScreen(report: state.extra as ReportItem?),
  ),
  GoRoute(
    path: AppRoutes.graduateActivities,
    name: AppRoutes.graduateActivitiesName,
    builder: (BuildContext context, GoRouterState state) =>
        const PracticalActivitiesScreen(),
  ),
  GoRoute(
    path: AppRoutes.graduateEvaluations,
    name: AppRoutes.graduateEvaluationsName,
    builder: (BuildContext context, GoRouterState state) =>
        const GraduateEvaluationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.graduateRecognition,
    name: AppRoutes.graduateRecognitionName,
    builder: (BuildContext context, GoRouterState state) =>
        const GraduateRecognitionScreen(),
  ),
];

// ---------------------------------------------------------------------------
// Mentor
// ---------------------------------------------------------------------------

/// The mentor bottom navigation branches.
final StatefulShellRoute _mentorShell = StatefulShellRoute.indexedStack(
  builder: (
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) =>
      RoleShell(navigationShell: navigationShell, items: AppNavItems.mentor),
  branches: <StatefulShellBranch>[
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.mentorDashboard,
          name: AppRoutes.mentorDashboardName,
          builder: (BuildContext context, GoRouterState state) =>
              const MentorDashboardScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.mentorNotifications,
          name: AppRoutes.mentorNotificationsName,
          // Renders the signed-in account's own notifications. The provider
          // behind it filters on the current user id, so it is correct for a
          // mentor even though the class carries the graduate name.
          builder: (BuildContext context, GoRouterState state) =>
              const GraduateNotificationsScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.mentorProfile,
          name: AppRoutes.mentorProfileName,
          // Edits the caller's own `profiles` row, which every role has and
          // row level security restricts to that row.
          builder: (BuildContext context, GoRouterState state) =>
              const GraduateProfileScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.mentorLinks,
          name: AppRoutes.mentorLinksName,
          builder: (BuildContext context, GoRouterState state) =>
              const ImportantLinksScreen(),
        ),
      ],
    ),
  ],
);

/// Mentor screens that cover the bottom navigation.
final List<RouteBase> _mentorFullScreenRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.mentorGraduates,
    name: AppRoutes.mentorGraduatesName,
    builder: (BuildContext context, GoRouterState state) =>
        const MentorGraduatesScreen(),
  ),
  GoRoute(
    path: AppRoutes.mentorReviews,
    name: AppRoutes.mentorReviewsName,
    builder: (BuildContext context, GoRouterState state) =>
        const MentorReviewsScreen(),
  ),
  GoRoute(
    path: AppRoutes.mentorEvidence,
    name: AppRoutes.mentorEvidenceName,
    builder: (BuildContext context, GoRouterState state) =>
        const MentorEvidenceScreen(),
  ),
  GoRoute(
    path: AppRoutes.mentorGraduateDetails,
    name: AppRoutes.mentorGraduateDetailsName,
    builder: (BuildContext context, GoRouterState state) =>
        MentorGraduateDetailsScreen(graduate: state.extra! as GraduateSummary),
  ),
  GoRoute(
    path: AppRoutes.mentorReportDetails,
    name: AppRoutes.mentorReportDetailsName,
    builder: (BuildContext context, GoRouterState state) =>
        MentorReportDetailsScreen(report: state.extra! as ReportItem),
  ),
  GoRoute(
    path: AppRoutes.mentorReportReview,
    name: AppRoutes.mentorReportReviewName,
    builder: (BuildContext context, GoRouterState state) =>
        MentorReportReviewScreen(report: state.extra! as ReportItem),
  ),
  GoRoute(
    path: AppRoutes.mentorEvaluations,
    name: AppRoutes.mentorEvaluationsName,
    builder: (BuildContext context, GoRouterState state) =>
        const MentorEvaluationsScreen(),
  ),
];

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

/// The administrator bottom navigation branches.
final StatefulShellRoute _adminShell = StatefulShellRoute.indexedStack(
  builder: (
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) =>
      RoleShell(navigationShell: navigationShell, items: AppNavItems.admin),
  branches: <StatefulShellBranch>[
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.adminDashboard,
          name: AppRoutes.adminDashboardName,
          builder: (BuildContext context, GoRouterState state) =>
              const AdminDashboardScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.adminNotifications,
          name: AppRoutes.adminNotificationsName,
          builder: (BuildContext context, GoRouterState state) =>
              const AdminNotificationsScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.adminProfile,
          name: AppRoutes.adminProfileName,
          // Edits the caller's own `profiles` row, which every role has and
          // row level security restricts to that row.
          builder: (BuildContext context, GoRouterState state) =>
              const GraduateProfileScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.adminLinks,
          name: AppRoutes.adminLinksName,
          builder: (BuildContext context, GoRouterState state) =>
              const ImportantLinksScreen(),
        ),
      ],
    ),
  ],
);

/// Administration screens that cover the bottom navigation.
final List<RouteBase> _adminFullScreenRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.adminGraduates,
    name: AppRoutes.adminGraduatesName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminGraduatesScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminMentors,
    name: AppRoutes.adminMentorsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminMentorsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminReportDetail,
    name: AppRoutes.adminReportDetailName,
    builder: (BuildContext context, GoRouterState state) =>
        AdminReportDetailScreen(report: state.extra! as ReportItem),
  ),
  GoRoute(
    path: AppRoutes.adminInstitutes,
    name: AppRoutes.adminInstitutesName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminInstitutesScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminEvaluations,
    name: AppRoutes.adminEvaluationsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminEvaluationsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminStatistics,
    name: AppRoutes.adminStatisticsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminStatisticsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminSettings,
    name: AppRoutes.adminSettingsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminEvidence,
    name: AppRoutes.adminEvidenceName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminEvidenceScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminWorkshop,
    name: AppRoutes.adminWorkshopName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminParticipantsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminActivities,
    name: AppRoutes.adminActivitiesName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminActivitiesScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminUser,
    name: AppRoutes.adminUserName,
    builder: (BuildContext context, GoRouterState state) =>
        AdminUserScreen(user: state.extra! as GraduateSummary),
  ),
  GoRoute(
    path: AppRoutes.adminWifaqs,
    name: AppRoutes.adminWifaqsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminWifaqsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminWifaqInstitutes,
    name: AppRoutes.adminWifaqInstitutesName,
    builder: (BuildContext context, GoRouterState state) =>
        AdminWifaqInstitutesScreen(wifaq: state.extra! as WifaqDirectoryEntry),
  ),
  GoRoute(
    path: AppRoutes.adminWifaqGraduates,
    name: AppRoutes.adminWifaqGraduatesName,
    builder: (BuildContext context, GoRouterState state) {
      final ({String title, String? instituteId, String? wifaqId}) target =
          state.extra! as ({String title, String? instituteId, String? wifaqId});
      return AdminWifaqGraduatesScreen(
        title: target.title,
        instituteId: target.instituteId,
        wifaqId: target.wifaqId,
      );
    },
  ),
  GoRoute(
    path: AppRoutes.adminCourses,
    name: AppRoutes.adminCoursesName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminCoursesScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminAssignments,
    name: AppRoutes.adminAssignmentsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminAssignmentsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminReports,
    name: AppRoutes.adminReportsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminReportsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminStandards,
    name: AppRoutes.adminStandardsName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminStandardsScreen(),
  ),
  GoRoute(
    path: AppRoutes.adminRecognition,
    name: AppRoutes.adminRecognitionName,
    builder: (BuildContext context, GoRouterState state) =>
        const AdminRecognitionScreen(),
  ),
];
