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

  /// Sign-up for an invited مربی or منتظم, with an invitation code in place
  /// of a رقم التسجیل.
  static const String staffSignUp = '/staff-sign-up';
  static const String staffSignUpName = 'staffSignUp';

  /// Where a password recovery link lands. Not public: the link signs the
  /// account in first, so there is always a session by the time it opens.
  static const String newPassword = '/new-password';
  static const String newPasswordName = 'newPassword';

  /// Shown when a signed-in account has no role granted yet.
  static const String noRole = '/no-role';
  static const String noRoleName = 'noRole';

  /// کمیونٹی بورڈ. No role prefix, because every signed-in role shares it.
  static const String communityBoard = '/community';
  static const String communityBoardName = 'communityBoard';

  /// One shared کارگزاری or board post, with its عوامی تبصرے.
  static const String communityItem = '/community/item';
  static const String communityItemName = 'communityItem';

  /// نئی پوسٹ, for a مربی or منتظم.
  static const String communityNewPost = '/community/new-post';
  static const String communityNewPostName = 'communityNewPost';

  /// Routes reachable without a session.
  static const Set<String> publicRoutes = <String>{
    welcome,
    signIn,
    signUp,
    staffSignUp,
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

  static const String graduateLinks = '/graduate/links';
  static const String graduateLinksName = 'graduateLinks';

  /// One practical activity's own screen, opened from the activity list.
  static const String graduateActivityDetail = '/graduate/activity-detail';
  static const String graduateActivityDetailName = 'graduateActivityDetail';

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

  static const String mentorNotifications = '/mentor/notifications';
  static const String mentorNotificationsName = 'mentorNotifications';

  static const String mentorProfile = '/mentor/profile';
  static const String mentorProfileName = 'mentorProfile';

  static const String mentorLinks = '/mentor/links';
  static const String mentorLinksName = 'mentorLinks';

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

  static const String adminWorkshop = '/admin/workshop';
  static const String adminWorkshopName = 'adminWorkshop';

  /// The form for adding one participant at a time.
  static const String adminAddParticipant = '/admin/workshop/add';
  static const String adminAddParticipantName = 'adminAddParticipant';

  static const String adminActivities = '/admin/activities';
  static const String adminActivitiesName = 'adminActivities';

  static const String adminUser = '/admin/user';
  static const String adminUserName = 'adminUser';

  /// Invitations, administrators, and accounts holding no role.
  static const String adminStaff = '/admin/staff';
  static const String adminStaffName = 'adminStaff';

  /// The form that invites a mentor or administrator.
  static const String adminAddStaff = '/admin/staff/add';
  static const String adminAddStaffName = 'adminAddStaff';

  static const String adminProfile = '/admin/profile';
  static const String adminProfileName = 'adminProfile';

  static const String adminLinks = '/admin/links';
  static const String adminLinksName = 'adminLinks';

  static const String adminEvidence = '/admin/evidence';
  static const String adminEvidenceName = 'adminEvidence';

  static const String adminSettings = '/admin/settings';
  static const String adminSettingsName = 'adminSettings';

  static const String adminInstitutes = '/admin/institutes';
  static const String adminInstitutesName = 'adminInstitutes';

  static const String adminEvaluations = '/admin/evaluations';
  static const String adminEvaluationsName = 'adminEvaluations';

  static const String adminStatistics = '/admin/statistics';
  static const String adminStatisticsName = 'adminStatistics';

  static const String adminReportDetail = '/admin/report-detail';
  static const String adminReportDetailName = 'adminReportDetail';

  /// Full screen administration routes.
  static const String adminWifaqs = '/admin/wifaqs';
  static const String adminWifaqsName = 'adminWifaqs';

  /// Institutes inside one wifaq, opened from [adminWifaqs].
  static const String adminWifaqInstitutes = '/admin/wifaqs/institutes';
  static const String adminWifaqInstitutesName = 'adminWifaqInstitutes';

  /// Graduates at one institute (or the unassigned-institute bucket),
  /// opened from [adminWifaqInstitutes].
  static const String adminWifaqGraduates = '/admin/wifaqs/graduates';
  static const String adminWifaqGraduatesName = 'adminWifaqGraduates';

  static const String adminCourses = '/admin/courses';
  static const String adminCoursesName = 'adminCourses';

  static const String adminAssignments = '/admin/assignments';
  static const String adminAssignmentsName = 'adminAssignments';

  static const String adminReports = '/admin/reports';
  static const String adminReportsName = 'adminReports';

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
    communityBoard,
    communityItem,
    communityNewPost,
    // Screens that used to be bottom-navigation branches. They are opened
    // from the dashboard now, so they push and carry a back button rather
    // than switching the bar underneath the user.
    graduateReports,
    graduateEvidence,
    graduateActivityDetail,
    adminEvidence,
    adminReportDetail,
    adminSettings,
    adminInstitutes,
    adminEvaluations,
    adminStatistics,
    mentorGraduates,
    mentorReviews,
    mentorEvidence,
    adminGraduates,
    adminMentors,
    graduateActivities,
    graduateReportEditor,
    graduateEvaluations,
    graduateRecognition,
    mentorGraduateDetails,
    mentorReportDetails,
    mentorReportReview,
    mentorEvaluations,
    adminWorkshop,
    adminAddParticipant,
    adminActivities,
    adminUser,
    adminStaff,
    adminAddStaff,
    adminWifaqs,
    adminWifaqInstitutes,
    adminWifaqGraduates,
    adminCourses,
    adminAssignments,
    adminReports,
    adminRecognition,
  };

  /// True when [path] must be pushed on top of the current screen so the user
  /// can return with the back button.
  static bool isFullScreen(String path) => fullScreenRoutes.contains(path);
}
