import 'work_items.dart';

/// Why a registration was accepted or refused.
///
/// The database returns a stable code rather than a sentence, so the wording
/// stays in the Urdu string table and the schema stays language-neutral.
enum CourseVerdict {
  ok,
  missingNumber,
  notFound,
  notEligible,
  alreadyUsed,
  nameMismatch,
  periodMismatch,
  unknown;

  static CourseVerdict fromCode(String? code) {
    switch (code) {
      case 'ok':
        return CourseVerdict.ok;
      case 'required':
        return CourseVerdict.missingNumber;
      case 'not_found':
        return CourseVerdict.notFound;
      case 'not_eligible':
        return CourseVerdict.notEligible;
      case 'already_used':
        return CourseVerdict.alreadyUsed;
      case 'name_mismatch':
        return CourseVerdict.nameMismatch;
      case 'period_mismatch':
        return CourseVerdict.periodMismatch;
      default:
        return CourseVerdict.unknown;
    }
  }
}

/// The outcome of checking a رقم التسجیل, and optionally a name, before
/// signup.
class CourseVerification {
  const CourseVerification({
    required this.valid,
    required this.verdict,
    this.participantName,
    this.participantPeriod,
  });

  final bool valid;

  /// The دورانیہ on record, returned only after number, name and period all
  /// matched, so the applicant can see the record really is theirs.
  final String? participantPeriod;
  final CourseVerdict verdict;

  /// Returned only on a valid match, so the applicant can confirm the record
  /// is theirs before creating an account.
  final String? participantName;

  factory CourseVerification.fromMap(Map<String, dynamic> row) {
    return CourseVerification(
      valid: row['valid'] == true,
      verdict: CourseVerdict.fromCode(row['reason'] as String?),
      participantName: nullableString(row, 'participant_name'),
      participantPeriod: nullableString(row, 'participant_period'),
    );
  }
}

/// A row of the course register — the organisation's master list of everyone
/// who completed the three-month course.
///
/// It deliberately holds only what the organisation's file carries. Category
/// (فاضل / فاضلہ), وفاق and institution are chosen by the participant during
/// registration and live on their profile, not here.
class CourseParticipant {
  const CourseParticipant({
    required this.id,
    required this.registrationNumber,
    required this.fullName,
    this.fatherName,
    this.effectiveGender,
    this.courseStartDate,
    this.courseCompletionDate,
    this.coursePeriodText,
    this.eligible = true,
    this.accountCreated = false,
    this.linkedUserId,
    this.gender,
  });

  final String id;

  /// رقم التسجیل — the unique identity of a participant.
  final String registrationNumber;

  /// The name as the organisation recorded it. Rows written before ولدیت had
  /// a column of its own may hold both names here, which is why registration
  /// accepts a name given either way rather than demanding one shape.
  final String fullName;

  /// ولدیت, for rows recorded since it had its own column. Null otherwise,
  /// and never arrived at by splitting [fullName].
  final String? fatherName;

  /// داخلہ ماہ, kept as written rather than forced into a calendar date.
  final String? courseStartDate;

  /// فراغت ماہ.
  final String? courseCompletionDate;

  /// دورانیہ, when the organisation records the period as one column.
  final String? coursePeriodText;

  /// Cleared by an administrator to bar someone from registering.
  final bool eligible;

  /// Set by the signup trigger when the number is claimed.
  final bool accountCreated;
  final String? linkedUserId;

  /// 'male' or 'female' as the organisation recorded it on the register
  /// row. Null means nobody has written it there, and it is shown as such
  /// rather than assumed. This is the column an منتظم edits.
  final String? gender;

  /// جنس as the dashboard counts it: [gender] when the register has one,
  /// otherwise the فاضل / فاضلہ the person chose for themselves at signup.
  /// Computed by `register_master`, so a figure and the rows behind it are
  /// one expression and cannot drift apart.
  final String? effectiveGender;

  /// فاضل, فاضلہ, or a plain statement that it is not recorded.
  String get genderLabel {
    switch (gender) {
      case 'male':
        return 'فاضل';
      case 'female':
        return 'فاضلہ';
      default:
        return 'درج نہیں';
    }
  }

  factory CourseParticipant.fromMap(Map<String, dynamic> row) {
    return CourseParticipant(
      id: row['id'] as String,
      registrationNumber: (row['registration_number'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      fatherName: nullableString(row, 'father_name'),
      // Absent when the row came from the table rather than the view; the
      // register's own column is then the best that is known.
      effectiveGender: nullableString(row, 'effective_gender') ??
          nullableString(row, 'gender'),
      courseStartDate: nullableString(row, 'course_start_date'),
      courseCompletionDate: nullableString(row, 'course_completion_date'),
      coursePeriodText: nullableString(row, 'course_period'),
      eligible: row['eligible'] != false,
      accountCreated: row['account_created'] == true,
      linkedUserId: nullableString(row, 'linked_user_id'),
      gender: nullableString(row, 'gender'),
    );
  }

  /// The course period as one line, or null when neither month is known.
  String? get coursePeriod {
    if (coursePeriodText != null && coursePeriodText!.trim().isNotEmpty) {
      return coursePeriodText!.trim();
    }
    final List<String> parts = <String>[
      if (courseStartDate != null && courseStartDate!.trim().isNotEmpty)
        courseStartDate!.trim(),
      if (courseCompletionDate != null &&
          courseCompletionDate!.trim().isNotEmpty)
        courseCompletionDate!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' — ');
  }
}

/// One recorded import of a participant file, so an administrator can see what
/// was loaded and when instead of inferring it from row counts.
class ImportBatch {
  const ImportBatch({
    required this.id,
    required this.fileName,
    this.totalRows = 0,
    this.importedRows = 0,
    this.duplicateRows = 0,
    this.invalidRows = 0,
    this.createdAt,
  });

  final String id;
  final String fileName;
  final int totalRows;
  final int importedRows;
  final int duplicateRows;
  final int invalidRows;
  final DateTime? createdAt;

  factory ImportBatch.fromMap(Map<String, dynamic> row) => ImportBatch(
        id: row['id'] as String,
        fileName: (row['file_name'] as String?) ?? '',
        totalRows: intOr(row, 'total_rows'),
        importedRows: intOr(row, 'imported_rows'),
        duplicateRows: intOr(row, 'duplicate_rows'),
        invalidRows: intOr(row, 'invalid_rows'),
        createdAt: dateOf(row, 'created_at'),
      );
}
