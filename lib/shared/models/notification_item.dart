import 'package:flutter/material.dart';

import 'urdu_dates.dart';
import 'work_items.dart';

/// The kind of notification, which decides its icon tint.
enum NotificationKind { report, review, recognition, reminder, system }

/// A single notification row.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    this.body,
    this.kind = NotificationKind.system,
    this.isUnread = false,
    this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> row) {
    return NotificationItem(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      body: nullableString(row, 'body'),
      kind: _kindFromDb(nullableString(row, 'kind')),
      isUnread: row['is_read'] != true,
      createdAt: dateOf(row, 'created_at'),
    );
  }

  static NotificationKind _kindFromDb(String? value) {
    switch (value) {
      case 'report':
        return NotificationKind.report;
      case 'review':
        return NotificationKind.review;
      case 'recognition':
        return NotificationKind.recognition;
      case 'reminder':
        return NotificationKind.reminder;
      default:
        return NotificationKind.system;
    }
  }

  final String id;

  /// Urdu title of the notification.
  final String title;

  /// Urdu body text.
  final String? body;
  final NotificationKind kind;
  final bool isUnread;
  final DateTime? createdAt;

  /// Urdu relative time label, for example two hours ago.
  String get timeLabel => UrduDates.relative(createdAt);

  /// Icon representing the notification kind.
  IconData get icon {
    switch (kind) {
      case NotificationKind.report:
        return Icons.description_outlined;
      case NotificationKind.review:
        return Icons.rate_review_outlined;
      case NotificationKind.recognition:
        return Icons.workspace_premium_outlined;
      case NotificationKind.reminder:
        return Icons.notifications_active_outlined;
      case NotificationKind.system:
        return Icons.info_outline;
    }
  }
}
