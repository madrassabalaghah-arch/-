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

/// The outcome of checking a رقمِ تسجیل, and optionally a name, before signup.
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
    this.courseStartDate,
    this.courseCompletionDate,
    this.coursePeriodText,
    this.eligible = true,
    this.accountCreated = false,
    this.linkedUserId,
    this.gender,
  });

  final String id;

  /// رقمِ تسجیل — the unique identity of a participant.
  final String registrationNumber;

  /// نام مع ولدیت — the name as the organisation recorded it.
  final String fullName;

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

  /// 'male' or 'female' as the organisation recorded it, or as the person
  /// chose at signup. Null means nobody has said, and it is counted as
  /// such rather than assumed.
  final String? gender;

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
