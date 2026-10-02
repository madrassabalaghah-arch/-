import 'package:flutter/material.dart';

import 'urdu_dates.dart';
import 'work_items.dart';

/// One row of the کمیونٹی بورڈ: either a کارگزاری a graduate chose to
/// share, or a post a مربی or منتظم wrote straight to the board.
///
/// Everything here comes from `community_feed()`, which returns only what
/// the board is allowed to show. There is no field for a phone number, a
/// رقمِ تسجیل or a نجی جائزہ, because the function never selects them.
class CommunityItem {
  const CommunityItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.authorName,
    this.reportId,
    this.body,
    this.authorRole,
    this.groupTitle,
    this.categoryTitle,
    this.activityDate,
    this.createdAt,
    this.commentCount = 0,
  });

  /// 'karguzari' or 'post'.
  final String kind;
  final String id;

  /// Set for a shared کارگزاری; null for a board post.
  final String? reportId;

  final String title;
  final String? body;
  final String authorName;

  /// 'graduate', 'mentor' or 'admin', for the line under the author's name.
  final String? authorRole;

  /// The main category and the sub-criterion it was filed under.
  final String? groupTitle;
  final String? categoryTitle;

  final DateTime? activityDate;
  final DateTime? createdAt;
  final int commentCount;

  bool get isKarguzari => kind == 'karguzari';

  IconData get icon =>
      isKarguzari ? Icons.description_outlined : Icons.campaign_outlined;

  String get dateLabel => UrduDates.label(createdAt);

  /// منتظم, مربی or فاضل / فاضلہ, for the author line.
  String get authorRoleLabel {
    switch (authorRole) {
      case 'admin':
        return 'منتظم';
      case 'mentor':
        return 'مربی';
      default:
        return 'فاضل / فاضلہ';
    }
  }

  factory CommunityItem.fromMap(Map<String, dynamic> row) {
    return CommunityItem(
      kind: (row['kind'] as String?) ?? 'post',
      id: row['id'] as String,
      reportId: nullableString(row, 'report_id'),
      title: (row['title'] as String?) ?? '',
      body: nullableString(row, 'body'),
      authorName: (row['author_name'] as String?) ?? '',
      authorRole: nullableString(row, 'author_role'),
      groupTitle: nullableString(row, 'group_title'),
      categoryTitle: nullableString(row, 'category_title'),
      activityDate: dateOf(row, 'activity_date'),
      createdAt: dateOf(row, 'created_at'),
      commentCount: intOr(row, 'comment_count'),
    );
  }
}

/// A عوامی تبصرہ. Public by definition: it carries the writer's name, and
/// it is never a نجی جائزہ, which lives in a different table the board
/// cannot read.
class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.body,
    this.authorName,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String? authorName;
  final String body;
  final DateTime? createdAt;

  String get dateLabel => UrduDates.label(createdAt);

  factory CommunityComment.fromMap(Map<String, dynamic> row) {
    final Object? author = row['author'] ?? row['profiles'];

    return CommunityComment(
      id: row['id'] as String,
      authorId: row['author_id'] as String,
      authorName: author is Map<String, dynamic>
          ? nullableString(author, 'full_name')
          : null,
      body: (row['body'] as String?) ?? '',
      createdAt: dateOf(row, 'created_at'),
    );
  }
}
