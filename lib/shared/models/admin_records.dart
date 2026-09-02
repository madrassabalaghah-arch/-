import 'app_status.dart';
import 'work_items.dart';

/// An examination board record.
class WifaqItem {
  const WifaqItem({
    required this.id,
    required this.name,
    this.city,
    this.status = AppStatus.active,
  });

  final String id;

  /// Urdu name of the board.
  final String name;
  final String? city;
  final AppStatus status;

  factory WifaqItem.fromMap(Map<String, dynamic> row) => WifaqItem(
        id: row['id'] as String,
        name: (row['name'] as String?) ?? '',
        city: nullableString(row, 'city'),
        status: AppStatusX.fromDb(nullableString(row, 'status')),
      );
}

/// An institute belonging to a board.
class InstituteItem {
  const InstituteItem({
    required this.id,
    required this.name,
    this.city,
    this.wifaqId,
    this.status = AppStatus.active,
  });

  final String id;
  final String name;
  final String? city;
  final String? wifaqId;
  final AppStatus status;

  factory InstituteItem.fromMap(Map<String, dynamic> row) => InstituteItem(
        id: row['id'] as String,
        name: (row['name'] as String?) ?? '',
        city: nullableString(row, 'city'),
        wifaqId: nullableString(row, 'wifaq_id'),
        status: AppStatusX.fromDb(nullableString(row, 'status')),
      );
}

/// A course offered to graduates.
class CourseItem {
  const CourseItem({
    required this.id,
    required this.title,
    this.durationLabel,
    this.status = AppStatus.active,
  });

  final String id;

  /// Urdu title of the course.
  final String title;

  /// Urdu duration label, for example six months.
  final String? durationLabel;
  final AppStatus status;

  factory CourseItem.fromMap(Map<String, dynamic> row) => CourseItem(
        id: row['id'] as String,
        title: (row['title'] as String?) ?? '',
        durationLabel: nullableString(row, 'duration_label'),
        status: AppStatusX.fromDb(nullableString(row, 'status')),
      );
}

/// An evaluation standard used when reviewing reports.
class StandardItem {
  const StandardItem({
    required this.id,
    required this.title,
    this.detail,
    this.weight = 0,
    this.status = AppStatus.active,
  });

  final String id;

  /// Urdu title of the standard.
  final String title;

  /// Urdu explanation of what the standard measures.
  final String? detail;

  /// Weight of the standard as a percentage.
  final int weight;
  final AppStatus status;

  factory StandardItem.fromMap(Map<String, dynamic> row) => StandardItem(
        id: row['id'] as String,
        title: (row['title'] as String?) ?? '',
        detail: nullableString(row, 'detail'),
        weight: intOr(row, 'weight'),
        status: AppStatusX.fromDb(nullableString(row, 'status')),
      );
}
