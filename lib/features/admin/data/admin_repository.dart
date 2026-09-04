import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// Everything the administrator area reads and writes.
///
/// These queries carry no ownership filter, because an administrator is
/// permitted to see the whole system. That permission is granted by the
/// `private.is_admin()` check inside each policy, not by this class — a
/// non-admin running the same query receives only their own rows.
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<int> _count(String table) async {
    return _client.from(table).count(CountOption.exact);
  }

  /// count() returns a filter builder, so the filter chains after it and the
  /// whole thing awaits to an int.
  Future<int> _countWhere(String table, String column, List<String> values) {
    return _client.from(table).count(CountOption.exact).inFilter(column, values);
  }

  /// Dashboard figures, every one of them a real count.
  Future<Map<String, int>> statistics() async {
    final List<int> counts = await Future.wait<int>(<Future<int>>[
      _count('profiles'),
      _countWhere('profiles', 'status', <String>['active']),
      _count('mentor_assignments'),
      _countWhere('reports', 'status', <String>['pending', 'draft']),
      _countWhere('reports', 'status', <String>['under_review', 'submitted']),
      _countWhere('reports', 'status', <String>['late']),
    ]);

    return <String, int>{
      'graduates': counts[0],
      'activeGraduates': counts[1],
      'mentorAssignments': counts[2],
      'pendingReports': counts[3],
      'underReview': counts[4],
      'lateReports': counts[5],
    };
  }

  /// The role held by every account, keyed by user id.
  Future<Map<String, AppRole>> rolesByUser() async {
    final List<Map<String, dynamic>> rows =
        await _client.from('user_roles').select('user_id, role');

    final Map<String, AppRole> roles = <String, AppRole>{};
    for (final Map<String, dynamic> row in rows) {
      final AppRole? role = AppRole.fromId(row['role'] as String?);
      if (role != null) {
        roles[row['user_id'] as String] = role;
      }
    }
    return roles;
  }

  /// Builds profile summaries for the given ids, or for everyone when [ids]
  /// is null.
  Future<List<GraduateSummary>> _profiles({List<String>? ids}) async {
    if (ids != null && ids.isEmpty) {
      return const <GraduateSummary>[];
    }

    final PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _client
        .from('profiles')
        .select('id, full_name, city, stage, status, institutes(name)');
    final List<Map<String, dynamic>> rows = ids == null
        ? await query.order('full_name')
        : await query.inFilter('id', ids).order('full_name');

    return rows.map((Map<String, dynamic> row) {
      final Object? institute = row['institutes'];
      return GraduateSummary(
        id: row['id'] as String,
        name: (row['full_name'] as String?) ?? '',
        instituteName:
            institute is Map<String, dynamic> ? institute['name'] as String? : null,
        city: row['city'] as String?,
        stage: row['stage'] as String?,
        status: AppStatusX.fromDb(row['status'] as String?),
      );
    }).toList();
  }

  /// Accounts that actually hold the graduate role.
  ///
  /// This filters by role rather than returning every profile. Without the
  /// filter a promoted mentor kept appearing in the فاضل / فاضلہ list as well
  /// as the مربی one, because every account has a profile row regardless of
  /// what it is.
  Future<List<GraduateSummary>> graduates() async {
    final Map<String, AppRole> roles = await rolesByUser();
    final List<String> ids = roles.entries
        .where((MapEntry<String, AppRole> e) => e.value == AppRole.graduate)
        .map((MapEntry<String, AppRole> e) => e.key)
        .toList();
    return _profiles(ids: ids);
  }

  /// Every account, whatever its role. Used by the administration screen,
  /// which must be able to open a mentor or an administrator too.
  Future<List<GraduateSummary>> allProfiles() => _profiles();

  /// Profiles that hold the mentor role, with their assignment counts.
  ///
  /// This deliberately does not embed `profiles` inside the `user_roles`
  /// query. `user_roles.user_id` has its foreign key to `auth.users`, not to
  /// `public.profiles`, so PostgREST has no relationship to traverse and the
  /// embed fails with PGRST200. The ids are fetched first and the profiles
  /// looked up separately instead.
  Future<List<MentorSummary>> mentors() async {
    final List<Map<String, dynamic>> roleRows = await _client
        .from('user_roles')
        .select('user_id')
        .eq('role', 'mentor');

    final List<String> ids = roleRows
        .map((Map<String, dynamic> row) => row['user_id'] as String)
        .toList();
    if (ids.isEmpty) {
      return const <MentorSummary>[];
    }

    final List<Map<String, dynamic>> profileRows = await _client
        .from('profiles')
        .select('id, full_name, city, status, institutes(name)')
        .inFilter('id', ids)
        .order('full_name');

    final List<Map<String, dynamic>> assignmentRows = await _client
        .from('mentor_assignments')
        .select('mentor_id')
        .eq('is_active', true);

    final Map<String, int> assignedCounts = <String, int>{};
    for (final Map<String, dynamic> row in assignmentRows) {
      final String id = row['mentor_id'] as String;
      assignedCounts[id] = (assignedCounts[id] ?? 0) + 1;
    }

    return profileRows.map((Map<String, dynamic> row) {
      final String id = row['id'] as String;
      final Object? institute = row['institutes'];
      return MentorSummary(
        id: id,
        name: (row['full_name'] as String?) ?? '',
        instituteName:
            institute is Map<String, dynamic> ? institute['name'] as String? : null,
        city: row['city'] as String?,
        graduateCount: assignedCounts[id] ?? 0,
        status: AppStatusX.fromDb(row['status'] as String?),
      );
    }).toList();
  }

  /// Every uploaded evidence file.
  ///
  /// No ownership filter is applied because the `evidence select permitted`
  /// policy already decides who may read a row: it calls
  /// `private.can_view_graduate()`, which admits the graduate who uploaded it,
  /// their mentor, and an administrator. A non-admin running this same query
  /// therefore receives only the rows they were already entitled to.
  Future<List<EvidenceItem>> evidence() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('evidence')
        .select()
        .order('created_at', ascending: false);
    return rows.map(EvidenceItem.fromMap).toList();
  }

  /// How many months pass between one کارگزاری and the next.
  ///
  /// Stored as a setting rather than compiled in, so the organisation can move
  /// between a monthly, two monthly or three monthly cycle at any time.
  Future<int> followUpInterval() async {
    final Map<String, dynamic>? row = await _client
        .from('app_settings')
        .select('value')
        .eq('key', 'follow_up_interval_months')
        .maybeSingle();
    final Object? value = row?['value'];
    if (value is int) {
      return value;
    }
    return int.tryParse('${value ?? ''}') ?? 3;
  }

  Future<void> setFollowUpInterval(int months) async {
    await _client.from('app_settings').upsert(<String, dynamic>{
      'key': 'follow_up_interval_months',
      'value': months,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<RecognitionRule>> recognitionRules() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('recognition_rules')
        .select()
        .order('created_at', ascending: false);
    return rows.map(RecognitionRule.fromMap).toList();
  }

  Future<void> createRecognitionRule({
    required String title,
    required RecognitionCriterion criterion,
    required int threshold,
    String? detail,
  }) async {
    await _client.from('recognition_rules').insert(<String, dynamic>{
      'title': title.trim(),
      'detail': detail?.trim().isEmpty ?? true ? null : detail!.trim(),
      'criterion': criterion.dbValue,
      'threshold': threshold < 1 ? 1 : threshold,
      'is_active': true,
    });
  }

  Future<void> setRuleActive({required String id, required bool active}) async {
    await _client
        .from('recognition_rules')
        .update(<String, dynamic>{'is_active': active})
        .eq('id', id);
  }

  Future<List<WifaqItem>> wifaqs() async {
    final List<Map<String, dynamic>> rows =
        await _client.from('wifaqs').select().order('name');
    return rows.map(WifaqItem.fromMap).toList();
  }

  /// Every wifaq with its institute and فاضل / فاضلہ counts, plus one row
  /// for graduates and institutes attached to no wifaq at all.
  ///
  /// This goes through the `wifaq_directory` RPC rather than a client-side
  /// join. `user_roles` is only readable by its own owner or an
  /// administrator, so a plain join done here would silently show zero
  /// graduates to a non-admin caller instead of failing — the database
  /// function raises instead of returning a wrong number.
  Future<List<WifaqDirectoryEntry>> wifaqDirectory() async {
    final List<dynamic> rows =
        await _client.rpc<List<dynamic>>('wifaq_directory');
    return rows
        .map((dynamic row) =>
            WifaqDirectoryEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// The institutes inside one wifaq, with their graduate counts, plus one
  /// row for graduates in that wifaq who named no institute. Pass `null` for
  /// the unassigned-wifaq bucket at the top of the hierarchy.
  Future<List<InstituteDirectoryEntry>> instituteDirectory(
      String? wifaqId) async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'institute_directory',
      params: <String, dynamic>{'p_wifaq_id': wifaqId},
    );
    return rows
        .map((dynamic row) =>
            InstituteDirectoryEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// The graduates at one leaf of the hierarchy the directory functions
  /// count: everyone attached to [instituteId], or — when
  /// [includeUnassignedInstitute] is set instead — everyone in [wifaqId] (or
  /// in no wifaq, when that is also null) who named no institute.
  Future<List<GraduateSummary>> graduatesIn({
    String? instituteId,
    bool includeUnassignedInstitute = false,
    String? wifaqId,
  }) async {
    final Map<String, AppRole> roles = await rolesByUser();
    final List<String> graduateIds = roles.entries
        .where((MapEntry<String, AppRole> e) => e.value == AppRole.graduate)
        .map((MapEntry<String, AppRole> e) => e.key)
        .toList();
    if (graduateIds.isEmpty) {
      return const <GraduateSummary>[];
    }

    final PostgrestFilterBuilder<List<Map<String, dynamic>>> base = _client
        .from('profiles')
        .select('id, full_name, city, stage, status, institutes(name)')
        .inFilter('id', graduateIds);

    final List<Map<String, dynamic>> rows;
    if (instituteId != null) {
      rows = await base.eq('institute_id', instituteId).order('full_name');
    } else if (includeUnassignedInstitute) {
      final PostgrestFilterBuilder<List<Map<String, dynamic>>>
          withoutInstitute = base.isFilter('institute_id', null);
      rows = await (wifaqId == null
              ? withoutInstitute.isFilter('wifaq_id', null)
              : withoutInstitute.eq('wifaq_id', wifaqId))
          .order('full_name');
    } else {
      rows = await base.order('full_name');
    }

    return rows.map((Map<String, dynamic> row) {
      final Object? institute = row['institutes'];
      return GraduateSummary(
        id: row['id'] as String,
        name: (row['full_name'] as String?) ?? '',
        instituteName: institute is Map<String, dynamic>
            ? institute['name'] as String?
            : null,
        city: row['city'] as String?,
        stage: row['stage'] as String?,
        status: AppStatusX.fromDb(row['status'] as String?),
      );
    }).toList();
  }

  Future<List<CourseItem>> courses() async {
    final List<Map<String, dynamic>> rows =
        await _client.from('courses').select().order('title');
    return rows.map(CourseItem.fromMap).toList();
  }

  Future<List<TaskItem>> assignments() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('assignments')
        .select('*, profiles!assignments_graduate_id_fkey(full_name)')
        .order('due_at');
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<List<StandardItem>> standards() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('evaluation_standards')
        .select()
        .order('weight', ascending: false);
    return rows.map(StandardItem.fromMap).toList();
  }

  Future<List<ReportItem>> reports() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('reports')
        .select('*, activities(title), profiles!reports_graduate_id_fkey(full_name)')
        .order('created_at', ascending: false);
    return rows.map(ReportItem.fromMap).toList();
  }

  Future<List<RecognitionItem>> recognitions() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('recognitions')
        .select()
        .order('awarded_at', ascending: false);
    return rows.map(RecognitionItem.fromMap).toList();
  }

  Future<List<NotificationItem>> notifications() async {
    final String uid = _client.auth.currentUser?.id ?? '';
    final List<Map<String, dynamic>> rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return rows.map(NotificationItem.fromMap).toList();
  }

  /// Assigns a graduate to a mentor.
  Future<void> assignGraduate({
    required String mentorId,
    required String graduateId,
  }) async {
    await _client.from('mentor_assignments').upsert(<String, dynamic>{
      'mentor_id': mentorId,
      'graduate_id': graduateId,
      'is_active': true,
    }, onConflict: 'mentor_id,graduate_id');
  }

  /// Grants a role. Only an administrator may do this; the policy enforces it.
  Future<void> grantRole({
    required String userId,
    required AppRole role,
  }) async {
    await _client.from('user_roles').upsert(<String, dynamic>{
      'user_id': userId,
      'role': role.id,
    }, onConflict: 'user_id,role');
  }

  // -------------------------------------------------------------------
  // Realtime
  // -------------------------------------------------------------------

  /// Every report in the system, live.
  ///
  /// An administrator's policies permit the whole table, so no client-side
  /// filter is needed here. The nested graduate name is not available over a
  /// stream, so the list falls back to the report's own columns; the detail
  /// screens still join for the full record.
  Stream<List<ReportItem>> watchReports() {
    return _client
        .from('reports')
        .stream(primaryKey: <String>['id'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) =>
            rows.map(ReportItem.fromMap).toList());
  }

  /// The administrator's own notifications, live.
  Stream<List<NotificationItem>> watchNotifications() {
    final String uid = _client.auth.currentUser?.id ?? '';
    return _client
        .from('notifications')
        .stream(primaryKey: <String>['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) =>
            rows.map(NotificationItem.fromMap).toList());
  }

  // -------------------------------------------------------------------
  // User administration
  // -------------------------------------------------------------------

  /// Replaces a user's role, keeping exactly one role per account.
  ///
  /// Deleting first is what makes the change a move rather than an addition:
  /// promoting a graduate to mentor must also stop them being a graduate,
  /// otherwise they would keep appearing in graduate listings. Only an
  /// administrator may call this, and the `user_roles` policy enforces that
  /// independently of this class.
  Future<void> setRole({
    required String userId,
    required AppRole role,
  }) async {
    await _client.from('user_roles').delete().eq('user_id', userId);
    await _client.from('user_roles').insert(<String, dynamic>{
      'user_id': userId,
      'role': role.id,
    });
  }

  /// The mentor currently supervising [graduateId], or null.
  Future<MentorSummary?> mentorOf(String graduateId) async {
    final Map<String, dynamic>? row = await _client
        .from('mentor_assignments')
        .select(
            'mentor_id, profiles!mentor_assignments_mentor_id_fkey(id, full_name, city, status, institutes(name))')
        .eq('graduate_id', graduateId)
        .eq('is_active', true)
        .maybeSingle();

    final Object? profile = row?['profiles'];
    if (profile is! Map<String, dynamic>) {
      return null;
    }
    final Object? institute = profile['institutes'];
    return MentorSummary(
      id: profile['id'] as String,
      name: (profile['full_name'] as String?) ?? '',
      instituteName:
          institute is Map<String, dynamic> ? institute['name'] as String? : null,
      city: profile['city'] as String?,
      status: AppStatusX.fromDb(profile['status'] as String?),
    );
  }

  /// Points a graduate at a mentor, or clears the assignment when
  /// [mentorId] is null.
  ///
  /// Existing assignments are deactivated rather than deleted, so the history
  /// of who supervised whom survives a reassignment.
  Future<void> assignMentor({
    required String graduateId,
    required String? mentorId,
  }) async {
    await _client
        .from('mentor_assignments')
        .update(<String, dynamic>{'is_active': false})
        .eq('graduate_id', graduateId)
        .eq('is_active', true);

    if (mentorId == null) {
      return;
    }

    await _client.from('mentor_assignments').upsert(<String, dynamic>{
      'mentor_id': mentorId,
      'graduate_id': graduateId,
      'is_active': true,
      'assigned_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'mentor_id,graduate_id');
  }

  /// The graduates currently supervised by [mentorId].
  Future<List<GraduateSummary>> graduatesOf(String mentorId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('mentor_assignments')
        .select(
            'profiles!mentor_assignments_graduate_id_fkey(id, full_name, city, stage, status, institutes(name))')
        .eq('mentor_id', mentorId)
        .eq('is_active', true);

    return rows
        .map((Map<String, dynamic> row) {
          final Object? profile = row['profiles'];
          if (profile is! Map<String, dynamic>) {
            return null;
          }
          final Object? institute = profile['institutes'];
          return GraduateSummary(
            id: profile['id'] as String,
            name: (profile['full_name'] as String?) ?? '',
            instituteName: institute is Map<String, dynamic>
                ? institute['name'] as String?
                : null,
            city: profile['city'] as String?,
            stage: profile['stage'] as String?,
            status: AppStatusX.fromDb(profile['status'] as String?),
          );
        })
        .whereType<GraduateSummary>()
        .toList();
  }

  /// Adds a wifaq. Only an administrator may do this; users choose from the
  /// list this produces.
  Future<WifaqItem> createWifaq({
    required String name,
    String? city,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('wifaqs')
        .insert(<String, dynamic>{
          'name': name.trim(),
          'city': city?.trim().isEmpty ?? true ? null : city!.trim(),
        })
        .select()
        .single();
    return WifaqItem.fromMap(row);
  }
}
