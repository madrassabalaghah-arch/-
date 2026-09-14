import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// Why a row of a participant file cannot be imported.
enum CandidateProblem {
  missingNumber,
  missingName,
  duplicateInFile,
  alreadyInDatabase,
  invalidMonth,
}

/// One row of a participant file after validation, carrying the reason it was
/// refused when it was.
class CandidateRow {
  const CandidateRow({
    required this.registrationNumber,
    required this.fullName,
    this.courseStartDate,
    this.courseCompletionDate,
    this.coursePeriod,
    this.problem,
  });

  final String registrationNumber;
  final String fullName;
  final String? courseStartDate;
  final String? courseCompletionDate;

  /// دورانیہ, for a file that records the period as one column.
  final String? coursePeriod;

  /// Null when the row is importable.
  final CandidateProblem? problem;

  bool get isValid => problem == null;

  CandidateRow withProblem(CandidateProblem? problem) => CandidateRow(
        registrationNumber: registrationNumber,
        fullName: fullName,
        courseStartDate: courseStartDate,
        courseCompletionDate: courseCompletionDate,
        coursePeriod: coursePeriod,
        problem: problem,
      );

  Map<String, dynamic> toInsert() => <String, dynamic>{
        'registration_number': registrationNumber,
        'full_name': fullName,
        'course_start_date': courseStartDate,
        'course_completion_date': courseCompletionDate,
        'course_period': coursePeriod,
      };
}

/// What an import would do, worked out before anything is written.
class ImportPreview {
  const ImportPreview({required this.rows});

  final List<CandidateRow> rows;

  int get total => rows.length;

  List<CandidateRow> get importable =>
      rows.where((CandidateRow r) => r.isValid).toList();

  int get valid => importable.length;

  int _count(Set<CandidateProblem> of) =>
      rows.where((CandidateRow r) => of.contains(r.problem)).length;

  /// Refused because the number is already accounted for, either in the
  /// database or earlier in the same file.
  int get duplicates => _count(<CandidateProblem>{
        CandidateProblem.duplicateInFile,
        CandidateProblem.alreadyInDatabase,
      });

  /// Refused because the row is incomplete or malformed.
  int get invalid => _count(<CandidateProblem>{
        CandidateProblem.missingNumber,
        CandidateProblem.missingName,
        CandidateProblem.invalidMonth,
      });
}

/// The course register: verification before signup, and administration of the
/// participant records themselves.
class CourseRepository {
  CourseRepository(this._client);

  final SupabaseClient _client;

  /// Checks a رقمِ تسجیل, and the name when one is supplied.
  ///
  /// Goes through an RPC rather than reading the table, because the caller is
  /// anonymous at this point and must not be able to browse the register. The
  /// function answers only about the one number given.
  Future<CourseVerification> verify(
    String registrationNumber, {
    String? fullName,
    String? coursePeriod,
  }) async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'verify_course_registration',
      params: <String, dynamic>{
        'p_registration_number': registrationNumber,
        'p_full_name': fullName,
        'p_course_period': coursePeriod,
      },
    );

    if (rows.isEmpty) {
      return const CourseVerification(
        valid: false,
        verdict: CourseVerdict.unknown,
      );
    }
    return CourseVerification.fromMap(rows.first as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------
  // Administration
  // -------------------------------------------------------------------

  Future<List<CourseParticipant>> participants() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('course_participants')
        .select()
        .order('created_at', ascending: false);
    return rows.map(CourseParticipant.fromMap).toList();
  }

  Future<void> addParticipant({
    required String registrationNumber,
    required String fullName,
    String? courseStartDate,
    String? courseCompletionDate,
    String? coursePeriod,
  }) async {
    await _client.from('course_participants').insert(<String, dynamic>{
      'registration_number': registrationNumber.trim(),
      'full_name': fullName.trim(),
      'course_start_date': _clean(courseStartDate),
      'course_completion_date': _clean(courseCompletionDate),
      'course_period': _clean(coursePeriod),
    });
  }

  /// True when this رقمِ تسجیل is already on the register.
  ///
  /// Compared on the same normalised key the database's unique index uses, so
  /// "MD-2026/001" and "md 2026 001" are recognised as one number and the
  /// administrator is told so in Urdu, before the insert would be refused.
  Future<bool> participantExists(String registrationNumber) async {
    final String key = _key(registrationNumber);
    if (key.isEmpty) {
      return false;
    }
    final Map<String, dynamic>? row = await _client
        .from('course_participants')
        .select('id')
        .eq('registration_key', key)
        .maybeSingle();
    return row != null;
  }

  /// Bars or restores a participant's ability to register.
  Future<void> setEligible({required String id, required bool eligible}) async {
    await _client
        .from('course_participants')
        .update(<String, dynamic>{'eligible': eligible})
        .eq('id', id);
  }

  Future<void> deleteParticipant(String id) async {
    await _client.from('course_participants').delete().eq('id', id);
  }

  /// Works out what an import would do, writing nothing.
  ///
  /// Duplicates are judged on the same normalised key the database uses, so
  /// "MD-1/2" and "md12" are recognised as one participant rather than
  /// slipping past as two.
  Future<ImportPreview> validate(List<CandidateRow> parsed) async {
    final List<Map<String, dynamic>> existing =
        await _client.from('course_participants').select('registration_number');
    final Set<String> seen = existing
        .map((Map<String, dynamic> r) =>
            _key((r['registration_number'] as String?) ?? ''))
        .toSet();

    final List<CandidateRow> checked = <CandidateRow>[];
    for (final CandidateRow row in parsed) {
      // A row that already failed parsing keeps the reason it carries.
      if (row.problem != null) {
        checked.add(row);
        continue;
      }

      final String key = _key(row.registrationNumber);
      if (seen.contains(key)) {
        checked.add(row.withProblem(CandidateProblem.alreadyInDatabase));
        continue;
      }

      // Added so a repeat later in the same file is caught as well.
      seen.add(key);
      checked.add(row);
    }
    return ImportPreview(rows: checked);
  }

  /// Writes the importable rows and records the import.
  ///
  /// Only rows the preview passed are written, so what the administrator
  /// confirmed is exactly what happens.
  Future<int> commit({
    required ImportPreview preview,
    required String fileName,
  }) async {
    final List<CandidateRow> rows = preview.importable;
    if (rows.isNotEmpty) {
      await _client.from('course_participants').insert(
            rows.map((CandidateRow r) => r.toInsert()).toList(),
          );
    }

    await _client.from('import_batches').insert(<String, dynamic>{
      'file_name': fileName,
      'total_rows': preview.total,
      'imported_rows': rows.length,
      'duplicate_rows': preview.duplicates,
      'invalid_rows': preview.invalid,
      'imported_by': _client.auth.currentUser?.id,
    });

    return rows.length;
  }

  Future<List<ImportBatch>> importHistory() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('import_batches')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(ImportBatch.fromMap).toList();
  }

  static String _key(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String? _clean(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value.trim();
}
