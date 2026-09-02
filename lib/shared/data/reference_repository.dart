import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Reads the shared reference lists, and lets a user add their institute.
///
/// Wifaqs are curated by the administrator, so this class only reads them —
/// there is no create method, and the `wifaqs` policies would refuse one
/// anyway. Institutes are different: a graduate may study somewhere not yet
/// listed, so they may add it.
class ReferenceRepository {
  ReferenceRepository(this._client);

  final SupabaseClient _client;

  Future<List<WifaqItem>> wifaqs() async {
    final List<Map<String, dynamic>> rows =
        await _client.from('wifaqs').select().order('name');
    return rows.map(WifaqItem.fromMap).toList();
  }

  /// Institutes, optionally narrowed to one wifaq.
  Future<List<InstituteItem>> institutes({String? wifaqId}) async {
    final PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
        _client.from('institutes').select();
    final List<Map<String, dynamic>> rows = wifaqId == null
        ? await query.order('name')
        : await query.eq('wifaq_id', wifaqId).order('name');
    return rows.map(InstituteItem.fromMap).toList();
  }

  /// Adds an institute and returns the stored row.
  ///
  /// It is attached to the wifaq the user selected, so the list stays
  /// organised rather than becoming one flat pile of names.
  Future<InstituteItem> createInstitute({
    required String name,
    required String wifaqId,
    String? city,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('institutes')
        .insert(<String, dynamic>{
          'name': name.trim(),
          'wifaq_id': wifaqId,
          'city': city?.trim().isEmpty ?? true ? null : city!.trim(),
        })
        .select()
        .single();
    return InstituteItem.fromMap(row);
  }

  /// The shared catalogue of practical activities.
  ///
  /// Every graduate chooses from this same list when filing a report, so it
  /// reads `activities` directly rather than the per-graduate progress table.
  /// Inactive entries are withheld: an administrator retires an activity by
  /// deactivating it, and retired work should not accept new reports.
  Future<List<ActivityItem>> activityCatalogue() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('activities')
        .select('id, title, detail, icon_key, total_steps, status')
        .eq('status', 'active')
        .order('title');
    return rows.map(ActivityItem.fromMap).toList();
  }

  /// Every activity including retired ones, for administration.
  Future<List<ActivityItem>> allActivities() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('activities')
        .select('id, title, detail, icon_key, total_steps, status')
        .order('title');
    return rows.map(ActivityItem.fromMap).toList();
  }

  /// Adds a catalogue activity. Administrators only; the `activities`
  /// policies reject anyone else.
  Future<ActivityItem> createActivity({
    required String title,
    required int totalSteps,
    String? detail,
    String iconKey = 'task',
  }) async {
    final Map<String, dynamic> row = await _client
        .from('activities')
        .insert(<String, dynamic>{
          'title': title.trim(),
          'detail': detail?.trim().isEmpty ?? true ? null : detail!.trim(),
          'icon_key': iconKey,
          'total_steps': totalSteps < 1 ? 1 : totalSteps,
          'status': 'active',
        })
        .select()
        .single();
    return ActivityItem.fromMap(row);
  }

  /// Retires or restores an activity.
  Future<void> setActivityStatus({
    required String id,
    required bool active,
  }) async {
    await _client
        .from('activities')
        .update(<String, dynamic>{'status': active ? 'active' : 'inactive'})
        .eq('id', id);
  }
}
