/// Every route path and route name used by the application.
///
/// Paths are declared once here so no screen ever navigates with a raw string.
class AppRoutes {
  const AppRoutes._();

  // ---------------------------------------------------------------------
  // Entry flow
  // ---------------------------------------------------------------------
  static const String welcome = '/';
  static const String welcomeName = 'welcome';

  static const String signIn = '/sign-in';
  static const String signInName = 'signIn';

  static const String signUp = '/sign-up';
  static const String signUpName = 'signUp';

  /// Shown when a signed-in account has no role granted yet.
  static const String noRole = '/no-role';
  static const String noRoleName = 'noRole';

  /// Routes reachable without a session.
  static const Set<String> publicRoutes = <String>{
    welcome,
    signIn,
    signUp,
  };

  // ---------------------------------------------------------------------
  // Graduate. The first five paths are the bottom navigation branches.
  // ---------------------------------------------------------------------
  static const String graduateDashboard = '/graduate/dashboard';
  static const String graduateDashboardName = 'graduateDashboard';

  static const String graduateReports = '/graduate/reports';
  static const String graduateReportsName = 'graduateReports';

  static const String graduateEvidence = '/graduate/evidence';
  static const String graduateEvidenceName = 'graduateEvidence';

  static const String graduateNotifications = '/graduate/notifications';
  static const String graduateNotificationsName = 'graduateNotifications';

  static const String graduateProfile = '/graduate/profile';
  static const String graduateProfileName = 'graduateProfile';

  static const String graduateReportEditor = '/graduate/report-editor';
  static const String graduateReportEditorName = 'graduateReportEditor';

  /// Full screen graduate routes that cover the bottom navigation.
  static const String graduateActivities = '/graduate/activities';
  static const String graduateActivitiesName = 'graduateActivities';

  static const String graduateEvaluations = '/graduate/evaluations';
  static const String graduateEvaluationsName = 'graduateEvaluations';

  static const String graduateRecognition = '/graduate/recognition';
  static const String graduateRecognitionName = 'graduateRecognition';

  // ---------------------------------------------------------------------
  // Mentor. The first four paths are the bottom navigation branches.
  // ---------------------------------------------------------------------
  static const String mentorDashboard = '/mentor/dashboard';
  static const String mentorDashboardName = 'mentorDashboard';

  static const String mentorGraduates = '/mentor/graduates';
  static const String mentorGraduatesName = 'mentorGraduates';

  static const String mentorReviews = '/mentor/reviews';
  static const String mentorReviewsName = 'mentorReviews';

  static const String mentorEvidence = '/mentor/evidence';
  static const String mentorEvidenceName = 'mentorEvidence';

  /// Full screen mentor routes.
  static const String mentorGraduateDetails = '/mentor/graduate-details';
  static const String mentorGraduateDetailsName = 'mentorGraduateDetails';

  static const String mentorReportDetails = '/mentor/report-details';
  static const String mentorReportDetailsName = 'mentorReportDetails';

  static const String mentorReportReview = '/mentor/report-review';
  static const String mentorReportReviewName = 'mentorReportReview';

  static const String mentorEvaluations = '/mentor/evaluations';
  static const String mentorEvaluationsName = 'mentorEvaluations';

  // ---------------------------------------------------------------------
  // Admin. The first four paths are the bottom navigation branches.
  // ---------------------------------------------------------------------
  static const String adminDashboard = '/admin/dashboard';
  static const String adminDashboardName = 'adminDashboard';

  static const String adminGraduates = '/admin/graduates';
  static const String adminGraduatesName = 'adminGraduates';

  static const String adminMentors = '/admin/mentors';
  static const String adminMentorsName = 'adminMentors';

  static const String adminNotifications = '/admin/notifications';
  static const String adminNotificationsName = 'adminNotifications';

  static const String adminActivities = '/admin/activities';
  static const String adminActivitiesName = 'adminActivities';

  static const String adminUser = '/admin/user';
  static const String adminUserName = 'adminUser';

  /// Full screen administration routes.
  static const String adminWifaqs = '/admin/wifaqs';
  static const String adminWifaqsName = 'adminWifaqs';

  static const String adminCourses = '/admin/courses';
  static const String adminCoursesName = 'adminCourses';

  static const String adminAssignments = '/admin/assignments';
  static const String adminAssignmentsName = 'adminAssignments';

  static const String adminReports = '/admin/reports';
  static const String adminReportsName = 'adminReports';

  static const String adminStandards = '/admin/standards';
  static const String adminStandardsName = 'adminStandards';

  static const String adminRecognition = '/admin/recognition';
  static const String adminRecognitionName = 'adminRecognition';

  // ---------------------------------------------------------------------
  // Route behaviour
  // ---------------------------------------------------------------------

  /// Routes that open as a full screen above the bottom navigation.
  ///
  /// Everything not listed here is a bottom navigation branch, which is
  /// switched rather than stacked. Navigation goes through this set so a
  /// screen never has to remember which kind of destination it is opening.
  static const Set<String> fullScreenRoutes = <String>{
    graduateActivities,
    graduateReportEditor,
    graduateEvaluations,
    graduateRecognition,
    mentorGraduateDetails,
    mentorReportDetails,
    mentorReportReview,
    mentorEvaluations,
    adminActivities,
    adminUser,
    adminWifaqs,
    adminCourses,
    adminAssignments,
    adminReports,
    adminStandards,
    adminRecognition,
  };

  /// True when [path] must be pushed on top of the current screen so the user
  /// can return with the back button.
  static bool isFullScreen(String path) => fullScreenRoutes.contains(path);
}
