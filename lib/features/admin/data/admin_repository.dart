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

  /// Dashboard figures, counted in the database where the facts live.
  ///
  /// This used to count rows of `profiles` and call the answer "فاضل /
  /// فاضلہ", which counted mentors and administrators too, and it read the
  /// mentor figure from `mentor_assignments`, which counts links rather than
  /// mentors — a mentor with nobody assigned was simply missing. One
  /// function now answers all of it, so the register, the accounts and the
  /// roles cannot be counted from three unrelated places again.
  Future<AdminStatistics> statistics() async {
    final Object? result =
        await _client.rpc<Object?>('admin_dashboard_statistics');
    final Object? row =
        result is List && result.isNotEmpty ? result.first : result;
    if (row is! Map<String, dynamic>) {
      return const AdminStatistics();
    }
    return AdminStatistics.fromMap(row);
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
        .select('id, full_name, email, city, stage, status, institutes(name)');
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
        email: row['email'] as String?,
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
        .select(
            '*, graduate:profiles!evidence_graduate_id_fkey(full_name, gender), '
            'report:reports!evidence_report_id_fkey(title)')
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

  /// Every institute with its graduate counts, across all wifaqs.
  Future<List<InstituteDirectoryEntry>> allInstitutes() async {
    final List<dynamic> rows =
        await _client.rpc<List<dynamic>>('institute_directory_all');
    return rows
        .map((dynamic r) =>
            InstituteDirectoryEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Every evaluation written, with both sides named: which mentor wrote it,
  /// about which فاضل / فاضلہ, on which کارگزاری.
  Future<List<EvaluationItem>> evaluations() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('evaluations')
        .select('*, report:reports(title), '
            'mentor:profiles!evaluations_mentor_id_fkey(full_name), '
            'graduate:profiles!evaluations_graduate_id_fkey(full_name)')
        .order('created_at', ascending: false);
    return rows.map(EvaluationItem.fromMap).toList();
  }

  /// Guidance and appreciation mentors have written, named the same way.
  Future<List<MentorFeedback>> mentorFeedback() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('mentor_feedback')
        .select('*, report:reports(title), '
            'mentor:profiles!mentor_feedback_mentor_id_fkey(full_name), '
            'graduate:profiles!mentor_feedback_graduate_id_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(MentorFeedback.fromMap).toList();
  }

  /// کارگزاری counted by status and by category.
  Future<List<({String section, String label, int total})>>
      karGuzariStatistics() async {
    final List<dynamic> rows =
        await _client.rpc<List<dynamic>>('karguzari_statistics');
    return rows.map((dynamic r) {
      final Map<String, dynamic> m = r as Map<String, dynamic>;
      return (
        section: (m['section'] as String?) ?? '',
        label: (m['label'] as String?) ?? '',
        total: (m['total'] as num?)?.toInt() ?? 0,
      );
    }).toList();
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
  /// A move rather than an addition: promoting a graduate to mentor must also
  /// stop them being a graduate, or they would keep appearing in graduate
  /// listings. It is one database call, so it happens completely or not at
  /// all. As a delete followed by an insert, a dropped connection between the
  /// two left the account with no role and in no list at all.
  ///
  /// `set_user_role` refuses anyone but an administrator, and refuses an
  /// administrator changing their own role. Removing a mentor or graduate
  /// role also ends the assignments that depended on it, because access to a
  /// graduate's records follows the assignment.
  Future<void> setRole({
    required String userId,
    required AppRole role,
  }) async {
    await _client.rpc<Object?>(
      'set_user_role',
      params: <String, dynamic>{'p_user_id': userId, 'p_role': role.id},
    );
  }

  // -------------------------------------------------------------------
  // Staff invitations
  // -------------------------------------------------------------------

  /// Invitations not yet used, newest first. Row level security shows them
  /// to administrators only.
  Future<List<StaffInvite>> openStaffInvites() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('staff_invites')
        .select()
        .isFilter('claimed_at', null)
        .order('created_at', ascending: false);
    return rows.map(StaffInvite.fromMap).toList();
  }

  /// Invites a مربی or منتظم who is not on the course register.
  ///
  /// The database issues the code, and refuses an address that already has
  /// an account or an open invitation, so what comes back is always usable.
  Future<StaffInvite> createStaffInvite({
    required String fullName,
    required String email,
    required AppRole role,
  }) async {
    final Object? result = await _client.rpc<Object?>(
      'create_staff_invite',
      params: <String, dynamic>{
        'p_full_name': fullName.trim(),
        'p_email': email.trim(),
        'p_role': role.id,
      },
    );
    // One row comes back as an object; accept a one-row list as well, so a
    // change in how the API wraps it cannot turn a created invitation into
    // an error message.
    final Object? row =
        result is List && result.isNotEmpty ? result.first : result;
    if (row is! Map<String, dynamic>) {
      throw StateError('create_staff_invite returned no invitation');
    }
    return StaffInvite.fromMap(row);
  }

  /// Withdraws an open invitation, so its code stops working.
  Future<void> cancelStaffInvite(String id) async {
    await _client.rpc<Object?>(
      'cancel_staff_invite',
      params: <String, dynamic>{'p_invite_id': id},
    );
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
