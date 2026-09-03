import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// The workshop register: verification before signup, and administration of
/// the records themselves.
class WorkshopRepository {
  WorkshopRepository(this._client);

  final SupabaseClient _client;

  /// Checks a registration number before an account exists.
  ///
  /// Goes through an RPC rather than reading the table, because the caller is
  /// anonymous at this point and must not be able to browse the register. The
  /// function returns a verdict for the one number supplied.
  Future<WorkshopVerification> verify(String registrationNumber) async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'verify_workshop_registration',
      params: <String, dynamic>{'p_registration_number': registrationNumber},
    );

    if (rows.isEmpty) {
      return const WorkshopVerification(
        valid: false,
        verdict: WorkshopVerdict.unknown,
      );
    }
    return WorkshopVerification.fromMap(rows.first as Map<String, dynamic>);
  }

  // -------------------------------------------------------------------
  // Administration
  // -------------------------------------------------------------------

  Future<List<WorkshopParticipant>> participants() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('workshop_participants')
        .select()
        .order('created_at', ascending: false);
    return rows.map(WorkshopParticipant.fromMap).toList();
  }

  Future<void> addParticipant({
    required String registrationNumber,
    required String fullName,
    String? fatherName,
    String? gender,
    String? phone,
    String? workshopName,
    String? batch,
    DateTime? workshopDate,
    bool completed = true,
  }) async {
    await _client.from('workshop_participants').insert(<String, dynamic>{
      'registration_number': registrationNumber.trim(),
      'full_name': fullName.trim(),
      'father_name': _clean(fatherName),
      'gender': gender,
      'phone': _clean(phone),
      'workshop_name': _clean(workshopName),
      'batch': _clean(batch),
      'workshop_date': workshopDate?.toIso8601String().substring(0, 10),
      'completed': completed,
    });
  }

  /// Flips attendance or eligibility on an existing record.
  Future<void> setFlags({
    required String id,
    bool? completed,
    bool? eligible,
  }) async {
    await _client.from('workshop_participants').update(<String, dynamic>{
      'completed': ?completed,
      'eligible': ?eligible,
    }).eq('id', id);
  }

  /// Removes a record. Refused by the database once an account has claimed
  /// it, because the profile would be left pointing at nothing.
  Future<void> deleteParticipant(String id) async {
    await _client.from('workshop_participants').delete().eq('id', id);
  }

  /// Imports many records at once, skipping any whose number is already
  /// present. Returns how many were written and how many were skipped.
  Future<({int imported, int skipped})> importParticipants(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return (imported: 0, skipped: 0);
    }

    // Existing keys are normalised the same way the database does, so
    // "WS-1/2" and "ws12" are recognised as the same record.
    final List<Map<String, dynamic>> existing =
        await _client.from('workshop_participants').select('registration_number');
    final Set<String> seen = existing
        .map((Map<String, dynamic> r) =>
            _key((r['registration_number'] as String?) ?? ''))
        .toSet();

    final List<Map<String, dynamic>> toInsert = <Map<String, dynamic>>[];
    int skipped = 0;
    for (final Map<String, dynamic> row in rows) {
      final String key = _key((row['registration_number'] as String?) ?? '');
      // Skips duplicates already stored and duplicates within the file.
      if (key.isEmpty || seen.contains(key)) {
        skipped++;
        continue;
      }
      seen.add(key);
      toInsert.add(row);
    }

    if (toInsert.isNotEmpty) {
      await _client.from('workshop_participants').insert(toInsert);
    }
    return (imported: toInsert.length, skipped: skipped);
  }

  static String _key(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String? _clean(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value.trim();
}
