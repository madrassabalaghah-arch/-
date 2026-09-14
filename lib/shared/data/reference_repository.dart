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

  /// Adds an institute, or returns the existing one when the same institution
  /// has already been registered under this wifaq.
  ///
  /// The database holds a normalised shadow of the name (`name_key`) with a
  /// unique index per wifaq, so "جامعہ اشاعت الاسلام" typed with stray spaces
  /// or a diacritic is recognised as the same institution rather than starting
  /// a second group. The name is stored exactly as the user wrote it; only the
  /// matching is normalised. A concurrent insert loses the race against that
  /// index, so the duplicate error is caught and the winning row returned.
  Future<InstituteItem> createInstitute({
    required String name,
    required String wifaqId,
    String? city,
  }) async {
    try {
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
    } on PostgrestException catch (error) {
      // 23505 is unique_violation: this institution already exists here.
      if (error.code != '23505') {
        rethrow;
      }
      final Map<String, dynamic> existing = await _client
          .from('institutes')
          .select()
          .eq('wifaq_id', wifaqId)
          .eq('name_key', _instituteKey(name))
          .single();
      return InstituteItem.fromMap(existing);
    }
  }

  /// Mirrors the `name_key` generated column so an existing institution can be
  /// looked up by the same rule the database matched on.
  static String _instituteKey(String name) {
    const String diacritics = 'ً-ْٰ';
    const String joiners = '​-‏';
    final String stripped = name.replaceAll(
      RegExp('[$diacritics$joiners]'),
      '',
    );

    final StringBuffer folded = StringBuffer();
    for (final int rune in stripped.runes) {
      // Arabic-Indic (٠-٩) and extended Arabic-Indic (۰-۹) digits fold to
      // Latin, so ۱۲ and 12 are the same institution.
      if (rune >= 0x0660 && rune <= 0x0669) {
        folded.write(rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        folded.write(rune - 0x06F0);
      } else {
        folded.writeCharCode(rune);
      }
    }

    return folded
        .toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
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

  /// The categories a کارگزاری can be filed under, in display order.
  Future<List<ReportCategory>> reportCategories() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('report_categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return rows.map(ReportCategory.fromMap).toList();
  }

  /// The curated اہم لنکس list.
  ///
  /// Retired links are withheld from readers by default; the administration
  /// view passes [includeInactive] so it can restore one.
  Future<List<ImportantLink>> importantLinks({
    bool includeInactive = false,
  }) async {
    final PostgrestFilterBuilder<List<Map<String, dynamic>>> query =
        _client.from('important_links').select();
    final List<Map<String, dynamic>> rows = includeInactive
        ? await query.order('sort_order').order('title')
        : await query
            .eq('status', 'active')
            .order('sort_order')
            .order('title');
    return rows.map(ImportantLink.fromMap).toList();
  }

  /// Adds a link. Administrators only; the `important_links` policies reject
  /// anyone else.
  Future<ImportantLink> createImportantLink({
    required String title,
    required String url,
    String? detail,
    String iconKey = 'link',
    int sortOrder = 0,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('important_links')
        .insert(<String, dynamic>{
          'title': title.trim(),
          'url': url.trim(),
          'detail': detail?.trim().isEmpty ?? true ? null : detail!.trim(),
          'icon_key': iconKey,
          'sort_order': sortOrder,
          'status': 'active',
        })
        .select()
        .single();
    return ImportantLink.fromMap(row);
  }

  /// Retires or restores a link.
  Future<void> setImportantLinkStatus({
    required String id,
    required bool active,
  }) async {
    await _client
        .from('important_links')
        .update(<String, dynamic>{'status': active ? 'active' : 'inactive'})
        .eq('id', id);
  }
}
