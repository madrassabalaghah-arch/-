import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../shared/models/models.dart';

/// Every read and write the graduate area performs.
///
/// No query relies on its own filter for security. Row level security already
/// restricts each table to the signed-in user's rows, so these queries return
/// the correct data even if a filter were omitted; the filters exist only to
/// keep result sets small.
class GraduateRepository {
  GraduateRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser?.id ?? '';

  Future<List<ReportItem>> reports() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('reports')
        .select('*, activities(title)')
        .eq('graduate_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(ReportItem.fromMap).toList();
  }

  Future<List<EvidenceItem>> evidence() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('evidence')
        .select()
        .eq('graduate_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(EvidenceItem.fromMap).toList();
  }

  Future<List<EvaluationItem>> evaluations() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('evaluations')
        .select('*, reports(title)')
        .eq('graduate_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(EvaluationItem.fromMap).toList();
  }

  Future<List<RecognitionItem>> recognitions() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('recognitions')
        .select()
        .eq('graduate_id', _uid)
        .order('awarded_at', ascending: false);
    return rows.map(RecognitionItem.fromMap).toList();
  }

  Future<List<NotificationItem>> notifications() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return rows.map(NotificationItem.fromMap).toList();
  }

  Future<List<ActivityItem>> activities() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('graduate_activities')
        .select('*, activities(id, title, detail, icon_key, total_steps)')
        .eq('graduate_id', _uid);
    return rows.map(ActivityItem.fromMap).toList();
  }

  Future<List<TaskItem>> pendingTasks() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('assignments')
        .select()
        .eq('graduate_id', _uid)
        .inFilter('status', <String>['pending', 'draft', 'late', 'active'])
        .order('due_at', ascending: true);
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<MentorFeedback?> latestFeedback() async {
    final Map<String, dynamic>? row = await _client
        .from('mentor_feedback')
        .select()
        .eq('graduate_id', _uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : MentorFeedback.fromMap(row);
  }

  Future<FollowUpItem?> nextFollowUp() async {
    final Map<String, dynamic>? row = await _client
        .from('follow_ups')
        .select()
        .eq('graduate_id', _uid)
        .order('scheduled_at', ascending: true)
        .limit(1)
        .maybeSingle();
    return row == null ? null : FollowUpItem.fromMap(row);
  }

  // -------------------------------------------------------------------
  // Realtime
  // -------------------------------------------------------------------

  /// Emits whenever any of this graduate's reports change.
  Stream<List<ReportItem>> watchReports() {
    return _client
        .from('reports')
        .stream(primaryKey: <String>['id'])
        .eq('graduate_id', _uid)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) =>
            rows.map(ReportItem.fromMap).toList());
  }

  /// Emits whenever this user's notifications change.
  Stream<List<NotificationItem>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: <String>['id'])
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) =>
            rows.map(NotificationItem.fromMap).toList());
  }

  /// Emits whenever a recognition is granted to this graduate.
  Stream<List<RecognitionItem>> watchRecognitions() {
    return _client
        .from('recognitions')
        .stream(primaryKey: <String>['id'])
        .eq('graduate_id', _uid)
        .order('awarded_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) =>
            rows.map(RecognitionItem.fromMap).toList());
  }

  // -------------------------------------------------------------------
  // Writes
  // -------------------------------------------------------------------

  /// Creates a report and returns the stored row, so the caller has its id.
  Future<ReportItem> createReport({
    required String title,
    String? summary,
    String? activityId,
    bool submit = false,
  }) async {
    final Map<String, dynamic> row = await _client
        .from('reports')
        .insert(<String, dynamic>{
          'graduate_id': _uid,
          'title': title,
          'summary': summary,
          'activity_id': activityId,
          'status': submit ? 'submitted' : 'draft',
          if (submit) 'submitted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('*, activities(title)')
        .single();
    return ReportItem.fromMap(row);
  }

  Future<void> updateReport({
    required String id,
    String? title,
    String? summary,
    bool submit = false,
  }) async {
    await _client.from('reports').update(<String, dynamic>{
      'title': ?title,
      'summary': ?summary,
      if (submit) ...<String, dynamic>{
        'status': 'submitted',
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
      },
    }).eq('id', id);
  }

  /// Deletes a draft. Row level security refuses anything already submitted.
  Future<void> deleteReport(String id) async {
    await _client.from('reports').delete().eq('id', id);
  }

  /// Saves the editable parts of the signed-in user's profile.
  ///
  /// [wifaqId] and [instituteId] are passed explicitly rather than through the
  /// null-aware spread, because clearing a selection is a real intent and must
  /// be able to write null.
  Future<void> updateProfile({
    String? fullName,
    String? fatherName,
    String? city,
    String? phone,
    String? email,
    String? wifaqId,
    String? instituteId,
    bool updatePlacement = false,
  }) async {
    await _client.from('profiles').update(<String, dynamic>{
      'full_name': ?fullName,
      'father_name': ?fatherName,
      'city': ?city,
      'phone': ?phone,
      'email': ?email,
      if (updatePlacement) 'wifaq_id': wifaqId,
      if (updatePlacement) 'institute_id': instituteId,
    }).eq('id', _uid);

    // Mirror the name into the auth account's metadata.
    //
    // `profiles.full_name` is what the application reads, but the Supabase
    // dashboard's Users list shows `raw_user_meta_data.full_name`. Writing
    // both keeps the two views consistent, so an administrator looking at
    // Authentication sees the same name the app shows. This only ever touches
    // the signed-in user's own metadata.
    if (fullName != null && fullName.trim().isNotEmpty) {
      await _client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{'full_name': fullName.trim()}),
      );
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _client
        .from('notifications')
        .update(<String, dynamic>{'is_read': true}).eq('id', id);
  }

  /// This graduate's own کارگزاری filed against one activity.
  ///
  /// Scoped to `_uid` so the activity screen shows the reader their own work;
  /// the `reports select permitted` policy would refuse anyone else's anyway.
  Future<List<ReportItem>> reportsForActivity(String activityId) async {
    final List<Map<String, dynamic>> rows = await _client
        .from('reports')
        .select('*, activities(title)')
        .eq('graduate_id', _uid)
        .eq('activity_id', activityId)
        .order('created_at', ascending: false);
    return rows.map(ReportItem.fromMap).toList();
  }

  /// The evidence attached to the given کارگزاری.
  Future<List<EvidenceItem>> evidenceForReports(List<String> reportIds) async {
    if (reportIds.isEmpty) {
      return const <EvidenceItem>[];
    }
    final List<Map<String, dynamic>> rows = await _client
        .from('evidence')
        .select()
        .inFilter('report_id', reportIds)
        .order('created_at', ascending: false);
    return rows.map(EvidenceItem.fromMap).toList();
  }

  /// A time-limited URL for a private evidence object.
  Future<String> signedEvidenceUrl(String storagePath) {
    return _client.storage
        .from(SupabaseConfig.evidenceBucket)
        .createSignedUrl(storagePath, SupabaseConfig.signedUrlSeconds);
  }

  // -------------------------------------------------------------------
  // Storage
  // -------------------------------------------------------------------

  /// Uploads a file to the private evidence bucket and records the row.
  ///
  /// The object path is always `<uid>/<timestamp>_<name>`. That prefix is not
  /// cosmetic: the storage policies compare the first path segment against
  /// `auth.uid()`, so a file can only ever be written into the uploader's own
  /// folder, and only the owner, their mentor or an administrator can read it.
  Future<EvidenceItem> uploadEvidence({
    required String fileName,
    required Uint8List bytes,
    required String kind,
    String? title,
    String? reportId,
    String? mimeType,
  }) async {
    final String uid = _uid;
    if (uid.isEmpty) {
      throw StateError('No signed-in user');
    }

    final String safeName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final String path =
        '$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage.from(SupabaseConfig.evidenceBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

    try {
      final Map<String, dynamic> row = await _client
          .from('evidence')
          .insert(<String, dynamic>{
            'graduate_id': uid,
            'report_id': reportId,
            'title': title?.trim().isNotEmpty == true
                ? title!.trim()
                : fileName,
            'kind': kind,
            'storage_path': path,
            'mime_type': mimeType,
            'size_bytes': bytes.length,
            'status': 'submitted',
          })
          .select()
          .single();
      return EvidenceItem.fromMap(row);
    } catch (error) {
      // The row is the record of truth. If it fails, do not leave an orphan
      // object sitting in the bucket.
      await _client.storage
          .from(SupabaseConfig.evidenceBucket)
          .remove(<String>[path]);
      rethrow;
    }
  }

  /// Removes an evidence row and its stored object together.
  Future<void> deleteEvidence(EvidenceItem item) async {
    await _client.from('evidence').delete().eq('id', item.id);
    await _client.storage
        .from(SupabaseConfig.evidenceBucket)
        .remove(<String>[item.storagePath]);
  }

  /// Emits whenever this graduate's evidence changes.
  Stream<List<EvidenceItem>> watchEvidence() {
    return _client
        .from('evidence')
        .stream(primaryKey: <String>['id'])
        .eq('graduate_id', _uid)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) =>
            rows.map(EvidenceItem.fromMap).toList());
  }

  /// Records that the graduate has done one more step of an activity.
  ///
  /// Called after a report is submitted. The `graduate_activities` row is
  /// created on first use rather than being pre-assigned, which is what lets
  /// a graduate pick any catalogue activity without an administrator
  /// enrolling them in it first. This is also what makes میرا سفر show real
  /// progress instead of staying at zero.
  Future<void> recordActivityProgress(String activityId) async {
    final Map<String, dynamic>? existing = await _client
        .from('graduate_activities')
        .select('id, completed_steps')
        .eq('graduate_id', _uid)
        .eq('activity_id', activityId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('graduate_activities').insert(<String, dynamic>{
        'graduate_id': _uid,
        'activity_id': activityId,
        'completed_steps': 1,
        'status': 'active',
      });
      return;
    }

    await _client.from('graduate_activities').update(<String, dynamic>{
      'completed_steps': (existing['completed_steps'] as int? ?? 0) + 1,
      'status': 'active',
    }).eq('id', existing['id'] as String);
  }
}
