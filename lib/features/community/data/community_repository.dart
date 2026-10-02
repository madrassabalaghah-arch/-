import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// The کمیونٹی بورڈ: what everybody may see, and what each role may add.
///
/// Reading goes through `community_feed()` and `community_karguzari()`,
/// which return a fixed set of safe columns. Writing goes to the tables
/// directly, where the policies decide: a مربی or منتظم may post, all three
/// roles may comment as themselves, nobody may edit another person's words,
/// and a منتظم moderates by hiding rather than deleting.
///
/// Nothing in this class can reach a نجی جائزہ. The review tables are not
/// queried here at all.
class CommunityRepository {
  CommunityRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser?.id ?? '';

  /// One page of the board, newest first. [before] is the created_at of the
  /// last row already shown, so the next page continues from there instead
  /// of loading everything.
  Future<List<CommunityItem>> feed({int limit = 20, DateTime? before}) async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'community_feed',
      params: <String, dynamic>{
        'p_limit': limit,
        'p_before': before?.toUtc().toIso8601String(),
      },
    );
    return rows
        .map((dynamic row) => CommunityItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// One shared کارگزاری, with the same safe columns the feed uses.
  Future<CommunityItem?> karguzari(String reportId) async {
    final List<dynamic> rows = await _client.rpc<List<dynamic>>(
      'community_karguzari',
      params: <String, dynamic>{'p_report_id': reportId},
    );
    if (rows.isEmpty) {
      return null;
    }
    final Map<String, dynamic> row = rows.first as Map<String, dynamic>;
    return CommunityItem.fromMap(<String, dynamic>{
      ...row,
      'kind': 'karguzari',
      'report_id': row['id'],
      'author_role': 'graduate',
    });
  }

  Future<List<CommunityComment>> comments({
    String? reportId,
    String? postId,
  }) async {
    final PostgrestFilterBuilder<List<Map<String, dynamic>>> query = _client
        .from('community_comments')
        .select(
            '*, author:profiles!community_comments_author_id_fkey(full_name)');

    final List<Map<String, dynamic>> rows = await (reportId != null
            ? query.eq('report_id', reportId)
            : query.eq('post_id', postId!))
        .order('created_at');

    return rows.map(CommunityComment.fromMap).toList();
  }

  /// Writes a عوامی تبصرہ as the signed-in user. The author is never taken
  /// from the caller: the policy refuses any row whose author is somebody
  /// else.
  Future<void> addComment({
    required String body,
    String? reportId,
    String? postId,
  }) async {
    await _client.from('community_comments').insert(<String, dynamic>{
      'author_id': _uid,
      'report_id': reportId,
      'post_id': postId,
      'body': body.trim(),
    });
  }

  /// A post written straight to the board. The policy allows this only for
  /// a مربی or a منتظم.
  Future<void> createPost({
    required String title,
    required String body,
  }) async {
    await _client.from('community_posts').insert(<String, dynamic>{
      'author_id': _uid,
      'title': title.trim(),
      'body': body.trim(),
    });
  }

  /// Moderation. The row is hidden, not destroyed, so nothing written is
  /// lost. Only an administrator's update passes the policy.
  Future<void> hidePost(String postId) async {
    await _client.from('community_posts').update(<String, dynamic>{
      'is_hidden': true,
      'hidden_by': _uid,
      'hidden_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', postId);
  }

  Future<void> hideComment(String commentId) async {
    await _client.from('community_comments').update(<String, dynamic>{
      'is_hidden': true,
      'hidden_by': _uid,
      'hidden_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', commentId);
  }

  /// The graduate's own choice to show a کارگزاری on the board, or to take
  /// it back down. Their own row, so the ordinary report policy covers it.
  Future<void> setShared({
    required String reportId,
    required bool shared,
  }) async {
    await _client.from('reports').update(<String, dynamic>{
      'shared_at': shared ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', reportId);
  }
}
