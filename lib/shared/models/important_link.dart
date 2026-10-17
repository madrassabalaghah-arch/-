import 'package:flutter/material.dart';

import 'app_status.dart';
import 'work_items.dart';

/// A curated entry of the اہم لنکس screen.
///
/// The list is administered, never generated: an administrator adds the
/// entries and everyone signed in reads them. Nothing here is seeded with
/// example links, so the screen is empty until real ones are added.
class ImportantLink {
  const ImportantLink({
    required this.id,
    required this.title,
    required this.url,
    this.detail,
    this.iconKey = 'link',
    this.sortOrder = 0,
    this.status = AppStatus.active,
  });

  final String id;

  /// Urdu label shown to the reader.
  final String title;

  /// The destination, opened in the device browser.
  final String url;

  /// Optional Urdu line explaining what the link is for.
  final String? detail;

  /// Chooses the leading icon without storing a Flutter type in the database.
  final String iconKey;

  /// Ascending display order; ties fall back to the title.
  final int sortOrder;
  final AppStatus status;

  bool get isActive => status == AppStatus.active;

  /// The icon for [iconKey], defaulting to a plain link.
  IconData get icon {
    switch (iconKey) {
      case 'web':
        return Icons.public_outlined;
      case 'video':
        return Icons.play_circle_outline;
      case 'book':
        return Icons.menu_book_outlined;
      case 'form':
        return Icons.assignment_outlined;
      case 'chat':
        return Icons.chat_outlined;
      case 'phone':
        return Icons.call_outlined;
      default:
        return Icons.link_outlined;
    }
  }

  factory ImportantLink.fromMap(Map<String, dynamic> row) => ImportantLink(
        id: row['id'] as String,
        title: (row['title'] as String?) ?? '',
        url: (row['url'] as String?) ?? '',
        detail: nullableString(row, 'detail'),
        iconKey: nullableString(row, 'icon_key') ?? 'link',
        sortOrder: intOr(row, 'sort_order'),
        status: AppStatusX.fromDb(nullableString(row, 'status')),
      );
}
