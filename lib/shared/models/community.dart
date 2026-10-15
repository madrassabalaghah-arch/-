import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'urdu_dates.dart';
import 'work_items.dart';

/// One row of the کمیونٹی بورڈ: either a کارگزاری a graduate chose to
/// share, or a post a مربی or منتظم wrote straight to the board.
///
/// Everything here comes from `community_feed()`, which returns only what
/// the board is allowed to show. There is no field for a phone number, a
/// رقم التسجیل or a نجی جائزہ, because the function never selects them.
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
    required this.body,
    this.authorName,
    this.authorRole,
    this.createdAt,
  });

  final String id;

  /// The author's name as `community_comments_for()` returned it, or null
  /// when there is no profile behind the row at all.
  final String? authorName;

  /// 'graduate', 'mentor' or 'admin'. The board names the author's standing
  /// beside their name, as the feed does.
  final String? authorRole;

  final String body;
  final DateTime? createdAt;

  String get dateLabel => UrduDates.label(createdAt);

  String? get authorRoleLabel {
    switch (authorRole) {
      case 'admin':
        return AppStrings.adminLabel;
      case 'mentor':
        return AppStrings.mentorLabel;
      case 'graduate':
        return AppStrings.graduateLabel;
      default:
        return null;
    }
  }

  /// The author, named, or a plain statement that the name is not recorded.
  /// Never the literal text "null": a تبصرہ whose author cannot be named is
  /// still a تبصرہ somebody wrote.
  String get authorLine {
    final String name = (authorName ?? '').trim();
    if (name.isEmpty) {
      return AppStrings.nameNotRecorded;
    }
    final String? role = authorRoleLabel;
    return role == null ? name : '$name — $role';
  }

  /// Built from `community_comments_for()`, which returns the author's name
  /// as a plain column. It is NOT read from an embedded profile: row level
  /// security on `profiles` rightly refuses one فاضل another's row, so an
  /// embed here came back null and printed as "null" on the board.
  factory CommunityComment.fromMap(Map<String, dynamic> row) {
    // An embedded profile is still accepted, for an منتظم's own screens
    // where the policy does permit the join.
    final Object? author = row['author'] ?? row['profiles'];

    return CommunityComment(
      id: row['id'] as String,
      authorName: author is Map<String, dynamic>
          ? nullableString(author, 'full_name')
          : nullableString(row, 'author_name'),
      authorRole: nullableString(row, 'author_role'),
      body: (row['body'] as String?) ?? '',
      createdAt: dateOf(row, 'created_at'),
    );
  }
}
