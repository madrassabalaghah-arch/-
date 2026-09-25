import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// The figures a مہمان may see.
///
/// Everything here goes through a database function rather than a table
/// read. The functions return counts and category names and nothing else, so
/// there is no row a guest could be shown by mistake and no table a guest
/// needs permission on. They answer a signed-out visitor too, which is why
/// nothing in this class touches the session.
class PublicRepository {
  PublicRepository(this._client);

  final SupabaseClient _client;

  Future<PublicStatistics> statistics() async {
    final List<dynamic> rows =
        await _client.rpc<List<dynamic>>('public_statistics');
    if (rows.isEmpty) {
      return const PublicStatistics();
    }
    return PublicStatistics.fromMap(rows.first as Map<String, dynamic>);
  }

  /// How much work sits under each category of practical service.
  Future<List<PublicActivityCount>> activityBreakdown() async {
    final List<dynamic> rows =
        await _client.rpc<List<dynamic>>('public_activity_breakdown');
    return rows
        .map((dynamic row) =>
            PublicActivityCount.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
