import 'work_items.dart';

/// Why a registration number was accepted or refused.
///
/// The database returns a stable code rather than a sentence, so the wording
/// stays in the Urdu string table and the schema stays language-neutral.
enum WorkshopVerdict {
  ok,
  notFound,
  notCompleted,
  notEligible,
  alreadyUsed,
  unknown;

  static WorkshopVerdict fromCode(String? code) {
    switch (code) {
      case 'ok':
        return WorkshopVerdict.ok;
      case 'not_found':
        return WorkshopVerdict.notFound;
      case 'not_completed':
        return WorkshopVerdict.notCompleted;
      case 'not_eligible':
        return WorkshopVerdict.notEligible;
      case 'already_used':
        return WorkshopVerdict.alreadyUsed;
      default:
        return WorkshopVerdict.unknown;
    }
  }
}

/// The outcome of checking a registration number before signup.
class WorkshopVerification {
  const WorkshopVerification({
    required this.valid,
    required this.verdict,
    this.participantName,
  });

  final bool valid;
  final WorkshopVerdict verdict;

  /// Returned only on a valid match, so the applicant can confirm the record
  /// is theirs before creating an account.
  final String? participantName;

  factory WorkshopVerification.fromMap(Map<String, dynamic> row) {
    return WorkshopVerification(
      valid: row['valid'] == true,
      verdict: WorkshopVerdict.fromCode(row['reason'] as String?),
      participantName: nullableString(row, 'participant_name'),
    );
  }
}

/// A row of the workshop register.
class WorkshopParticipant {
  const WorkshopParticipant({
    required this.id,
    required this.registrationNumber,
    required this.fullName,
    this.fatherName,
    this.gender,
    this.phone,
    this.workshopName,
    this.batch,
    this.workshopDate,
    this.completed = false,
    this.eligible = true,
    this.accountCreated = false,
    this.userId,
  });

  final String id;
  final String registrationNumber;
  final String fullName;
  final String? fatherName;

  /// 'male' or 'female' — drives the فاضل / فاضلہ split.
  final String? gender;
  final String? phone;
  final String? workshopName;
  final String? batch;
  final DateTime? workshopDate;

  /// Attendance and permission are separate: someone may have attended and
  /// still be barred from the app.
  final bool completed;
  final bool eligible;

  /// Set by the signup trigger when the number is claimed.
  final bool accountCreated;
  final String? userId;

  factory WorkshopParticipant.fromMap(Map<String, dynamic> row) {
    return WorkshopParticipant(
      id: row['id'] as String,
      registrationNumber: (row['registration_number'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      fatherName: nullableString(row, 'father_name'),
      gender: nullableString(row, 'gender'),
      phone: nullableString(row, 'phone'),
      workshopName: nullableString(row, 'workshop_name'),
      batch: nullableString(row, 'batch'),
      workshopDate: dateOf(row, 'workshop_date'),
      completed: row['completed'] == true,
      eligible: row['eligible'] == true,
      accountCreated: row['account_created'] == true,
      userId: nullableString(row, 'user_id'),
    );
  }

  /// Urdu label for the participant's category.
  String get genderLabel {
    switch (gender) {
      case 'male':
        return 'فاضل';
      case 'female':
        return 'فاضلہ';
      default:
        return '—';
    }
  }
}
