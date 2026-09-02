import 'package:flutter/material.dart';

import 'urdu_dates.dart';
import 'work_items.dart';

/// How prominent an award is. Higher tiers earn the full gold gradient card.
enum RecognitionTier { milestone, award, appreciation }

/// An achievement, award or milestone.
class RecognitionItem {
  const RecognitionItem({
    required this.id,
    required this.title,
    required this.graduateId,
    this.detail,
    this.awardedBy,
    this.tier = RecognitionTier.appreciation,
    this.awardedAt,
  });

  final String id;

  /// Urdu title of the award.
  final String title;
  final String graduateId;

  /// Urdu description of why it was awarded.
  final String? detail;

  /// Urdu name of the awarding mentor or institution.
  final String? awardedBy;
  final RecognitionTier tier;
  final DateTime? awardedAt;

  factory RecognitionItem.fromMap(Map<String, dynamic> row) {
    final Object? awarder = row['profiles'];

    return RecognitionItem(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      graduateId: row['graduate_id'] as String,
      detail: nullableString(row, 'detail'),
      awardedBy: awarder is Map<String, dynamic>
          ? nullableString(awarder, 'full_name')
          : null,
      tier: _tierFromDb(nullableString(row, 'tier')),
      awardedAt: dateOf(row, 'awarded_at'),
    );
  }

  static RecognitionTier _tierFromDb(String? value) {
    switch (value) {
      case 'milestone':
        return RecognitionTier.milestone;
      case 'award':
        return RecognitionTier.award;
      default:
        return RecognitionTier.appreciation;
    }
  }

  String get dateLabel => UrduDates.label(awardedAt);

  /// Icon chosen from the tier, so icons stay UI constants.
  IconData get icon {
    switch (tier) {
      case RecognitionTier.milestone:
        return Icons.military_tech_outlined;
      case RecognitionTier.award:
        return Icons.emoji_events_outlined;
      case RecognitionTier.appreciation:
        return Icons.favorite_outline;
    }
  }

  /// Urdu label of the tier, shown as a small chip.
  String get tierLabel {
    switch (tier) {
      case RecognitionTier.milestone:
        return 'سنگِ میل';
      case RecognitionTier.award:
        return 'اعزاز';
      case RecognitionTier.appreciation:
        return 'حوصلہ افزائی';
    }
  }
}
