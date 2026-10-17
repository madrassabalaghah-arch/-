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
      activeAssignments: intOr(row, 'active_assignments'),
      pendingReports: intOr(row, 'pending_reports'),
      underReview: intOr(row, 'under_review'),
      lateReports: intOr(row, 'late_reports'),
    );
  }
}
