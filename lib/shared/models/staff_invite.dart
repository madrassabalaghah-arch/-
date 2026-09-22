import 'app_role.dart';
import 'work_items.dart';

/// Why an invitation was accepted or refused before signup.
///
/// The database returns a stable code rather than a sentence, so the wording
/// stays in the Urdu string table and the schema stays language-neutral.
enum StaffInviteVerdict {
  ok,
  missing,
  notFound,
  alreadyUsed,
  emailRegistered,
  unknown;

  static StaffInviteVerdict fromCode(String? code) {
    switch (code) {
      case 'ok':
        return StaffInviteVerdict.ok;
      case 'required':
        return StaffInviteVerdict.missing;
      case 'not_found':
        return StaffInviteVerdict.notFound;
      case 'already_used':
        return StaffInviteVerdict.alreadyUsed;
      case 'email_registered':
        return StaffInviteVerdict.emailRegistered;
      default:
        return StaffInviteVerdict.unknown;
    }
  }
}

/// The outcome of checking an email and an invitation code before signup.
class StaffInviteCheck {
  const StaffInviteCheck({
    required this.valid,
    required this.verdict,
    this.name,
    this.role,
  });

  final bool valid;
  final StaffInviteVerdict verdict;

  /// Returned only when the email and the code both matched, so the person
  /// can see the invitation really is theirs before choosing a password.
  final String? name;
  final AppRole? role;

  factory StaffInviteCheck.fromMap(Map<String, dynamic> row) {
    return StaffInviteCheck(
      valid: row['valid'] == true,
      verdict: StaffInviteVerdict.fromCode(row['reason'] as String?),
      name: nullableString(row, 'invite_name'),
      role: AppRole.fromId(row['invite_role'] as String?),
    );
  }
}

/// An invitation for a مربی or منتظم who is not on the course register.
///
/// The administrator records the name, email and role; the database issues
/// the code. The person then signs up with that email and that code, and the
/// signup trigger grants the role.
class StaffInvite {
  const StaffInvite({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.code,
    this.createdAt,
    this.claimedAt,
  });

  final String id;
  final String fullName;
  final String email;

  /// Null only for a value this build does not recognise, which is shown as
  /// such rather than guessed at.
  final AppRole? role;

  /// Eight characters, single use. Row level security shows it to
  /// administrators and nobody else.
  final String code;
  final DateTime? createdAt;
  final DateTime? claimedAt;

  bool get isOpen => claimedAt == null;

  /// The code in two groups of four, which is easier to read out and type.
  String get displayCode => formatCode(code);

  static String formatCode(String code) {
    final String clean = normaliseCode(code);
    return clean.length == 8
        ? '${clean.substring(0, 4)}-${clean.substring(4)}'
        : clean;
  }

  /// What the database compares: upper case, letters and digits only, so a
  /// code typed as "abcd-2345" or "ABCD 2345" still matches.
  static String normaliseCode(String code) =>
      code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  factory StaffInvite.fromMap(Map<String, dynamic> row) {
    return StaffInvite(
      id: row['id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      email: (row['email'] as String?) ?? '',
      role: AppRole.fromId(row['role'] as String?),
      code: (row['code'] as String?) ?? '',
      createdAt: dateOf(row, 'created_at'),
      claimedAt: dateOf(row, 'claimed_at'),
    );
  }
}
