import 'work_items.dart';

/// The administrator's figures, as `admin_dashboard_statistics()` counts them.
///
/// Two different questions are kept apart here, because one number cannot
/// answer both:
///
/// * **کل** — every eligible record in the course register, whether or not
///   that person ever created an account.
/// * **فعال** — the records that are linked to an account holding the
///   graduate role. Importing a row, or having a number and a name, does not
///   make anybody active.
class AdminStatistics {
  const AdminStatistics({
    this.totalMale = 0,
    this.totalFemale = 0,
    this.totalUnrecordedGender = 0,
    this.totalGraduates = 0,
    this.activeMale = 0,
    this.activeFemale = 0,
    this.activeUnrecorded = 0,
    this.activeGraduates = 0,
    this.accountsWithoutRecord = 0,
    this.mentors = 0,
    this.admins = 0,
    this.guests = 0,
    this.activeAssignments = 0,
    this.pendingReports = 0,
    this.underReview = 0,
    this.lateReports = 0,
  });

  /// کل فاضل and کل فاضلہ, from the register.
  final int totalMale;
  final int totalFemale;

  /// Register records whose فاضل / فاضلہ is not recorded anywhere yet. They
  /// are counted in [totalGraduates] but in neither of the two above, so the
  /// figures are shown rather than quietly folded into one of them.
  final int totalUnrecordedGender;
  final int totalGraduates;

  final int activeMale;
  final int activeFemale;
  final int activeUnrecorded;
  final int activeGraduates;

  /// Graduate accounts that no register record points at. A gap to close,
  /// not an achievement to display.
  final int accountsWithoutRecord;

  /// Accounts holding each role. A mentor counts because they hold the
  /// role, not because somebody is assigned to them.
  final int mentors;
  final int admins;
  final int guests;

  /// Mentor-to-graduate links currently in force.
  final int activeAssignments;

  final int pendingReports;
  final int underReview;
  final int lateReports;

  factory AdminStatistics.fromMap(Map<String, dynamic> row) {
    return AdminStatistics(
      totalMale: intOr(row, 'total_male'),
      totalFemale: intOr(row, 'total_female'),
      totalUnrecordedGender: intOr(row, 'total_unrecorded_gender'),
      totalGraduates: intOr(row, 'total_graduates'),
      activeMale: intOr(row, 'active_male'),
      activeFemale: intOr(row, 'active_female'),
      activeUnrecorded: intOr(row, 'active_unrecorded'),
      activeGraduates: intOr(row, 'active_graduates'),
      accountsWithoutRecord: intOr(row, 'accounts_without_record'),
      mentors: intOr(row, 'mentors'),
      admins: intOr(row, 'admins'),
      guests: intOr(row, 'guests'),
      activeAssignments: intOr(row, 'active_assignments'),
      pendingReports: intOr(row, 'pending_reports'),
      underReview: intOr(row, 'under_review'),
      lateReports: intOr(row, 'late_reports'),
    );
  }
}

/// What a مہمان may see: totals, and nothing about any one person.
///
/// Drafts are left out of every figure here, because a draft is a working
/// copy its author has not submitted.
class PublicStatistics {
  const PublicStatistics({
    this.totalMale = 0,
    this.totalFemale = 0,
    this.totalGraduates = 0,
    this.totalReports = 0,
    this.socialActivities = 0,
    this.practicalServices = 0,
    this.completedProjects = 0,
  });

  final int totalMale;
  final int totalFemale;
  final int totalGraduates;

  /// مجموعی کارگزاریاں.
  final int totalReports;

  /// معاشرتی و اصلاحی سرگرمیاں.
  final int socialActivities;

  /// عملی خدمات — the کارگزاری filed under every other group.
  final int practicalServices;

  /// مکمل شدہ عملی منصوبے.
  final int completedProjects;

  factory PublicStatistics.fromMap(Map<String, dynamic> row) {
    return PublicStatistics(
      totalMale: intOr(row, 'total_male'),
      totalFemale: intOr(row, 'total_female'),
      totalGraduates: intOr(row, 'total_graduates'),
      totalReports: intOr(row, 'total_reports'),
      socialActivities: intOr(row, 'social_activities'),
      practicalServices: intOr(row, 'practical_services'),
      completedProjects: intOr(row, 'completed_projects'),
    );
  }
}

/// One category of practical work, with how much has been recorded under it.
///
/// Category names and counts only: no graduate, no title, no date.
class PublicActivityCount {
  const PublicActivityCount({
    required this.groupTitle,
    required this.categoryTitle,
    required this.total,
  });

  final String groupTitle;
  final String categoryTitle;
  final int total;

  factory PublicActivityCount.fromMap(Map<String, dynamic> row) {
    return PublicActivityCount(
      groupTitle: (row['group_title'] as String?) ?? '',
      categoryTitle: (row['category_title'] as String?) ?? '',
      total: intOr(row, 'total'),
    );
  }
}
