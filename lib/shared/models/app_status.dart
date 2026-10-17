import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The single status vocabulary used across the whole application.
///
/// Every list row, badge and filter reads its Urdu label and its colours from
/// here, so a status looks and reads identically on every screen.
enum AppStatus {
  draft(
    dbValue: 'draft',
    urduLabel: 'مسودہ',
    foreground: AppColors.gray,
    background: AppColors.lightGray,
    icon: Icons.edit_note_outlined,
  ),
  pending(
    dbValue: 'pending',
    urduLabel: 'زیرِ التوا',
    foreground: AppColors.warning,
    background: AppColors.goldTint,
    icon: Icons.hourglass_empty_outlined,
  ),
  submitted(
    dbValue: 'submitted',
    urduLabel: 'جمع کروا دی گئی',
    foreground: AppColors.primaryGreen,
    background: AppColors.greenTint,
    icon: Icons.upload_file_outlined,
  ),
  underReview(
    dbValue: 'under_review',
    urduLabel: 'زیرِ جائزہ',
    foreground: AppColors.earthBrown,
    background: AppColors.goldTint,
    icon: Icons.rate_review_outlined,
  ),
  revisionRequired(
    dbValue: 'revision_required',
    urduLabel: 'اصلاح درکار',
    foreground: AppColors.warning,
    background: AppColors.goldTint,
    icon: Icons.edit_outlined,
  ),
  completed(
    dbValue: 'completed',
    urduLabel: 'مکمل',
    foreground: AppColors.tealGreen,
    background: AppColors.greenTint,
    icon: Icons.check_circle_outline,
  ),
  late(
    dbValue: 'late',
    urduLabel: 'تاخیر سے',
    foreground: AppColors.error,
    background: AppColors.errorSurface,
    icon: Icons.schedule_outlined,
  ),
  inactive(
    dbValue: 'inactive',
    urduLabel: 'غیر فعال',
    foreground: AppColors.gray,
    background: AppColors.lightGray,
    icon: Icons.pause_circle_outline,
  ),
  active(
    dbValue: 'active',
    urduLabel: 'فعال',
    foreground: AppColors.oliveGreen,
    background: AppColors.greenTint,
    icon: Icons.play_circle_outline,
  );

  const AppStatus({
    required this.dbValue,
    required this.urduLabel,
    required this.foreground,
    required this.background,
    required this.icon,
  });

  /// The exact value stored in the Postgres `work_status` enum.
  final String dbValue;

  /// Urdu label displayed inside badges and filters.
  final String urduLabel;

  /// Text and icon colour of the badge.
  final Color foreground;

  /// Badge surface colour.
  final Color background;

  /// Icon shown beside the label.
  final IconData icon;
}

/// Conversion between the database enum and [AppStatus].
extension AppStatusX on AppStatus {
  /// Maps a `work_status` value from Postgres.
  ///
  /// Falls back to [AppStatus.pending] for an unknown or missing value so a
  /// row still renders rather than crashing the list.
  static AppStatus fromDb(String? value) {
    if (value == null) {
      return AppStatus.pending;
    }
    for (final AppStatus status in AppStatus.values) {
      if (status.dbValue == value) {
        return status;
      }
    }
    return AppStatus.pending;
  }
}
