import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// Everything the mentor area reads and writes.
///
/// Every query is scoped to the graduates actually assigned to this mentor.
/// The scoping is enforced twice: here for a small result set, and in
/// Postgres by `private.is_mentor_of()`, which is the guard that actually
/// matters. An unassigned graduate is unreachable even by a crafted request.
class MentorRepository {
  MentorRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser?.id ?? '';

  /// Ids of the graduates assigned to this mentor.
  Future<List<String>> assignedGraduateIds() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('mentor_assignments')
        .select('graduate_id')
        .eq('mentor_id', _uid)
        .eq('is_active', true);
    return rows
        .map((Map<String, dynamic> row) => row['graduate_id'] as String)
        .toList();
  }

  /// The assigned graduates, with progress computed from their real
  /// activity rows rather than stored on the profile.
  Future<List<GraduateSummary>> assignedGraduates() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('mentor_assignments')
        .select(
            'graduate_id, profiles!mentor_assignments_graduate_id_fkey(id, full_name, city, stage, status, institutes(name))')
        .eq('mentor_id', _uid)
        .eq('is_active', true);

    if (rows.isEmpty) {
      return const <GraduateSummary>[];
    }

    final List<String> ids = rows
        .map((Map<String, dynamic> row) => row['graduate_id'] as String)
        .toList();

    final Map<String, List<int>> progress = await _progressFor(ids);

    return rows
        .map((Map<String, dynamic> row) {
          final Object? profile = row['profiles'];
          if (profile is! Map<String, dynamic>) {
            return null;
          }
          final String id = profile['id'] as String;
          final List<int> steps = progress[id] ?? const <int>[0, 0];
          final Object? institute = profile['institutes'];

          return GraduateSummary(
            id: id,
            name: (profile['full_name'] as String?) ?? '',
            instituteName: institute is Map<String, dynamic>
                ? institute['name'] as String?
                : null,
            city: profile['city'] as String?,
            stage: profile['stage'] as String?,
            status: AppStatusX.fromDb(profile['status'] as String?),
            completedSteps: steps[0],
            totalSteps: steps[1],
          );
        })
        .whereType<GraduateSummary>()
        .toList();
  }

  /// Sums completed and total steps per graduate.
  Future<Map<String, List<int>>> _progressFor(List<String> graduateIds) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('graduate_activities')
        .select('graduate_id, completed_steps, activities(total_steps)')
        .inFilter('graduate_id', graduateIds);

    final Map<String, List<int>> result = <String, List<int>>{};
    for (final Map<String, dynamic> row in rows) {
      final String id = row['graduate_id'] as String;
      final Object? activity = row['activities'];
      final int total = activity is Map<String, dynamic>
          ? (activity['total_steps'] as int? ?? 0)
          : 0;
      final int done = row['completed_steps'] as int? ?? 0;
      final List<int> current =
          result.putIfAbsent(id, () => <int>[0, 0]);
      current[0] += done;
      current[1] += total;
    }
    return result;
  }

  Future<List<ReportItem>> incomingReports() async {
    final List<String> ids = await assignedGraduateIds();
    if (ids.isEmpty) {
      return const <ReportItem>[];
    }
    final List<Map<String, dynamic>> rows = await _client
        .from('reports')
        .select('*, activities(title), profiles!reports_graduate_id_fkey(full_name)')
        .inFilter('graduate_id', ids)
        .order('created_at', ascending: false);
    return rows.map(ReportItem.fromMap).toList();
  }

  Future<List<EvidenceItem>> evidence() async {
    final List<String> ids = await assignedGraduateIds();
    if (ids.isEmpty) {
      return const <EvidenceItem>[];
    }
    final List<Map<String, dynamic>> rows = await _client
        .from('evidence')
        .select()
        .inFilter('graduate_id', ids)
        .order('created_at', ascending: false);
    return rows.map(EvidenceItem.fromMap).toList();
  }

  Future<List<EvaluationItem>> completedEvaluations() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('evaluations')
        .select('*, reports(title)')
        .eq('mentor_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(EvaluationItem.fromMap).toList();
  }

  Future<List<NotificationItem>> notifications() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(NotificationItem.fromMap).toList();
  }

  /// Records an evaluation against a report, with its per-standard scores.
  Future<void> submitEvaluation({
    required String reportId,
    required String graduateId,
    required Map<String, int> scoresByStandard,
    required int maxScore,
    String? comment,
  }) async {
    final int total = scoresByStandard.values.fold<int>(0, (int a, int b) => a + b);

    final Map<String, dynamic> evaluation = await _client
        .from('evaluations')
        .upsert(<String, dynamic>{
          'report_id': reportId,
          'mentor_id': _uid,
          'graduate_id': graduateId,
          'comment': comment,
          'total_score': total,
          'max_score': maxScore,
          'status': 'completed',
        }, onConflict: 'report_id,mentor_id')
        .select()
        .single();

    final String evaluationId = evaluation['id'] as String;

    if (scoresByStandard.isNotEmpty) {
      await _client.from('evaluation_scores').upsert(
            scoresByStandard.entries
                .map((MapEntry<String, int> e) => <String, dynamic>{
                      'evaluation_id': evaluationId,
                      'standard_id': e.key,
                      'score': e.value,
                    })
                .toList(),
            onConflict: 'evaluation_id,standard_id',
          );
    }

    // Move the report out of the review queue.
    await _client
        .from('reports')
        .update(<String, dynamic>{'status': 'completed'}).eq('id', reportId);
  }

  /// Writes guidance for an assigned graduate.
  Future<void> sendFeedback({
    required String graduateId,
    required String subject,
    required String message,
  }) async {
    await _client.from('mentor_feedback').insert(<String, dynamic>{
      'mentor_id': _uid,
      'graduate_id': graduateId,
      'subject': subject,
      'message': message,
    });
  }

  // -------------------------------------------------------------------
  // Realtime
  // -------------------------------------------------------------------

  /// Emits whenever a report belonging to one of this mentor's assigned
  /// graduates changes.
  ///
  /// Supabase streams cannot express "graduate_id IN (...)", so the assigned
  /// ids are resolved first and the stream is filtered client-side. Row level
  /// security still applies to the socket, so an unassigned graduate's row
  /// never reaches the client in the first place — the filter only trims what
  /// is already permitted.
  Stream<List<ReportItem>> watchIncomingReports() async* {
    final List<String> ids = await assignedGraduateIds();
    if (ids.isEmpty) {
      yield const <ReportItem>[];
      return;
    }
    final Set<String> allowed = ids.toSet();

    yield* _client
        .from('reports')
        .stream(primaryKey: <String>['id'])
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) => rows
            .where((Map<String, dynamic> row) =>
                allowed.contains(row['graduate_id'] as String?))
            .map(ReportItem.fromMap)
            .toList());
  }

  /// Emits whenever this mentor's own notifications change.
  Stream<List<NotificationItem>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: <String>['id'])
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) =>
            rows.map(NotificationItem.fromMap).toList());
  }
}
