import 'package:flutter/material.dart';

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

/// on the dashboard comes from the database rather than from this file.
class ReportCategory {
  const ReportCategory({
    required this.id,
    required this.key,
    required this.groupKey,
    required this.groupTitle,
    required this.title,
    this.sortOrder = 0,
  });

  final String id;

  /// Stable identifier, for example `teaching`.
  final String key;

  /// Which heading the category sits under, for example `social`.
  final String groupKey;
  final String groupTitle;
  final String title;
  final int sortOrder;

  /// The group whose کارگزاری count as سماجی و دعوتی کردار.
  static const String socialGroup = 'social_dawah';

  /// The icon of this sub criterion, and of the main شعبہ it sits under.
  /// Both live with the model so the dashboard and the کارگزاری form cannot
  /// drift apart.
  IconData get icon => reportCategoryIcon(key);
  IconData get groupIcon => reportGroupIcon(groupKey);

  factory ReportCategory.fromMap(Map<String, dynamic> row) => ReportCategory(
        id: row['id'] as String,
        key: (row['key'] as String?) ?? '',
        groupKey: (row['group_key'] as String?) ?? '',
        groupTitle: (row['group_title'] as String?) ?? '',
        title: (row['title'] as String?) ?? '',
        sortOrder: intOr(row, 'sort_order'),
      );
}

/// The icon of one of the twelve ذیلی معیار.
IconData reportCategoryIcon(String key) {
  switch (key) {
    // ذاتی و علمی ترقی
    case 'positive_personal_change':
      return Icons.self_improvement_outlined;
    case 'academic_research':
      return Icons.menu_book_outlined;
    case 'technical_skills':
      return Icons.devices_outlined;
    // مسجد و مدرسہ میں عملی کردار
    case 'teaching_improvement':
      return Icons.school_outlined;
    case 'mosque_madrasa_change':
      return Icons.mosque_outlined;
    case 'people_building':
      return Icons.groups_2_outlined;
    // سماجی و دعوتی کردار
    case 'positive_social_role':
      return Icons.volunteer_activism_outlined;
    case 'outreach_influence':
      return Icons.campaign_outlined;
    case 'unity_cooperation':
      return Icons.handshake_outlined;
    // عملی نتائج و اثرات
    case 'observable_results':
      return Icons.fact_check_outlined;
    case 'effectiveness':
      return Icons.trending_up;
    case 'continuity':
      return Icons.repeat_outlined;
    default:
      return Icons.category_outlined;
  }
}

/// The icon of one of the four بنیادی شعبے.
IconData reportGroupIcon(String groupKey) {
  switch (groupKey) {
    case 'personal_academic':
      return Icons.auto_stories_outlined;
    case 'mosque_madrasa':
      return Icons.mosque_outlined;
    case ReportCategory.socialGroup:
      return Icons.groups_outlined;
    case 'results_impact':
      return Icons.insights_outlined;
    default:
      return Icons.category_outlined;
  }
}
