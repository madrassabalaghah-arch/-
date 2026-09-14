import 'package:flutter/material.dart';

import 'app_status.dart';
import 'urdu_dates.dart';

/// Reads a nullable, non-empty string from a Supabase row.
String? nullableString(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

/// Reads an integer that may arrive as int, num or null.
int intOr(Map<String, dynamic> row, String key, [int fallback = 0]) {
  final Object? value = row[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

/// Reads a timestamp column.
DateTime? dateOf(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  return value is String ? DateTime.tryParse(value) : null;
}

/// A practical activity a graduate records work against, joined with that
/// graduate's progress row.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    this.detail,
    this.iconKey,
    this.status = AppStatus.pending,
    this.completed = 0,
    this.total = 1,
  });

  final String id;
  final String title;
  final String? detail;

  /// Key mapping onto a Flutter icon; icons stay UI constants.
  final String? iconKey;
  final AppStatus status;
  final int completed;
  final int total;

  factory ActivityItem.fromMap(Map<String, dynamic> row) {
    // graduate_activities rows embed the activity under `activities`.
    final Object? activity = row['activities'];
    final Map<String, dynamic> source =
        activity is Map<String, dynamic> ? activity : row;

    return ActivityItem(
      id: (source['id'] ?? row['id']) as String,
      title: (source['title'] as String?) ?? '',
      detail: nullableString(source, 'detail'),
      iconKey: nullableString(source, 'icon_key'),
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      completed: intOr(row, 'completed_steps'),
      total: intOr(source, 'total_steps', 1),
    );
  }

  double get progress => total == 0 ? 0 : (completed / total).clamp(0, 1);

  IconData get icon => activityIcon(iconKey);
}

/// Maps a stored icon key onto a Material icon, defaulting sensibly.
IconData activityIcon(String? key) {
  switch (key) {
    case 'menu_book':
      return Icons.menu_book_outlined;
    case 'school':
      return Icons.school_outlined;
    case 'groups':
      return Icons.groups_outlined;
    case 'volunteer':
      return Icons.volunteer_activism_outlined;
    default:
      return Icons.task_alt_outlined;
  }
}

/// A performance report.
class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.graduateId,
    this.summary,
    this.graduateName,
    this.activityType,
    this.status = AppStatus.draft,
    this.submittedAt,
    this.dueAt,
    this.createdAt,
    this.categoryId,
  });

  final String id;
  final String title;
  final String graduateId;

  /// The `report_categories` row this کارگزاری was filed under, if any.
  final String? categoryId;
  final String? summary;
  final String? graduateName;
  final String? activityType;
  final AppStatus status;
  final DateTime? submittedAt;
  final DateTime? dueAt;
  final DateTime? createdAt;

  factory ReportItem.fromMap(Map<String, dynamic> row) {
    final Object? profile = row['profiles'];
    final Object? activity = row['activities'];

    return ReportItem(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      graduateId: row['graduate_id'] as String,
      summary: nullableString(row, 'summary'),
      graduateName: profile is Map<String, dynamic>
          ? nullableString(profile, 'full_name')
          : null,
      activityType: activity is Map<String, dynamic>
          ? nullableString(activity, 'title')
          : null,
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      submittedAt: dateOf(row, 'submitted_at'),
      dueAt: dateOf(row, 'due_at'),
      createdAt: dateOf(row, 'created_at'),
      categoryId: nullableString(row, 'category_id'),
    );
  }

  /// Urdu date line for the list row.
  String get dateLabel => UrduDates.label(submittedAt ?? createdAt);
}

/// A file attached as supporting evidence.
class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.title,
    required this.graduateId,
    required this.storagePath,
    this.reportId,
    this.kind = 'document',
    this.mimeType,
    this.sizeBytes,
    this.status = AppStatus.submitted,
    this.createdAt,
    this.reviewNote,
  });

  /// What the reviewer said, shown to the graduate beside the verdict.
  final String? reviewNote;

  final String id;
  final String title;
  final String graduateId;

  /// Object path inside the private evidence bucket.
  final String storagePath;
  final String? reportId;

  /// Matches the `evidence_kind` enum: image, video or document.
  final String kind;
  final String? mimeType;
  final int? sizeBytes;
  final AppStatus status;
  final DateTime? createdAt;

  factory EvidenceItem.fromMap(Map<String, dynamic> row) {
    return EvidenceItem(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      graduateId: row['graduate_id'] as String,
      storagePath: (row['storage_path'] as String?) ?? '',
      reportId: nullableString(row, 'report_id'),
      kind: nullableString(row, 'kind') ?? 'document',
      mimeType: nullableString(row, 'mime_type'),
      sizeBytes: row['size_bytes'] == null ? null : intOr(row, 'size_bytes'),
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      createdAt: dateOf(row, 'created_at'),
      reviewNote: nullableString(row, 'review_note'),
    );
  }

  /// The verdict in the words the brief uses for evidence, which differ from
  /// those used for a کارگزاری: a file is approved, not "completed".
  String get reviewLabel {
    switch (status) {
      case AppStatus.completed:
        return 'منظور شدہ';
      case AppStatus.revisionRequired:
        return 'مزید معلومات درکار ہیں';
      default:
        return 'زیرِ جائزہ';
    }
  }

  /// Urdu name of the file kind.
  String get typeLabel {
    switch (kind) {
      case 'image':
        return 'تصویر';
      case 'video':
        return 'ویڈیو';
      default:
        return 'دستاویز';
    }
  }

  IconData get icon {
    switch (kind) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String get sizeLabel => UrduDates.fileSize(sizeBytes);

  String get dateLabel => UrduDates.label(createdAt);
}

/// The outcome of a mentor evaluation.
class EvaluationItem {
  const EvaluationItem({
    required this.id,
    required this.reportId,
    required this.graduateId,
    required this.mentorId,
    this.title,
    this.reviewerName,
    this.comment,
    this.score = 0,
    this.maxScore = 0,
    this.status = AppStatus.underReview,
    this.createdAt,
  });

  final String id;
  final String reportId;
  final String graduateId;
  final String mentorId;
  final String? title;
  final String? reviewerName;
  final String? comment;
  final int score;
  final int maxScore;
  final AppStatus status;
  final DateTime? createdAt;

  factory EvaluationItem.fromMap(Map<String, dynamic> row) {
    final Object? report = row['reports'];
    final Object? mentor = row['profiles'];

    return EvaluationItem(
      id: row['id'] as String,
      reportId: row['report_id'] as String,
      graduateId: row['graduate_id'] as String,
      mentorId: row['mentor_id'] as String,
      title: report is Map<String, dynamic>
          ? nullableString(report, 'title')
          : null,
      reviewerName: mentor is Map<String, dynamic>
          ? nullableString(mentor, 'full_name')
          : null,
      comment: nullableString(row, 'comment'),
      score: intOr(row, 'total_score'),
      maxScore: intOr(row, 'max_score'),
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      createdAt: dateOf(row, 'created_at'),
    );
  }

  double get ratio => maxScore == 0 ? 0 : (score / maxScore).clamp(0, 1);

  String get dateLabel => UrduDates.label(createdAt);
}

/// A duty assigned to a graduate. Also drives the pending-task list.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.graduateId,
    this.detail,
    this.assignedToName,
    this.status = AppStatus.pending,
    this.dueAt,
  });

  final String id;
  final String title;
  final String graduateId;
  final String? detail;
  final String? assignedToName;
  final AppStatus status;
  final DateTime? dueAt;

  factory TaskItem.fromMap(Map<String, dynamic> row) {
    final Object? profile = row['profiles'];

    return TaskItem(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      graduateId: row['graduate_id'] as String,
      detail: nullableString(row, 'detail'),
      assignedToName: profile is Map<String, dynamic>
          ? nullableString(profile, 'full_name')
          : null,
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      dueAt: dateOf(row, 'due_at'),
    );
  }

  String get dueLabel => UrduDates.due(dueAt);

  IconData get icon => Icons.assignment_outlined;
}

/// A scheduled follow-up between a mentor and a graduate.
class FollowUpItem {
  const FollowUpItem({
    required this.id,
    required this.title,
    required this.graduateId,
    this.detail,
    this.status = AppStatus.pending,
    this.scheduledAt,
  });

  final String id;
  final String title;
  final String graduateId;
  final String? detail;
  final AppStatus status;
  final DateTime? scheduledAt;

  factory FollowUpItem.fromMap(Map<String, dynamic> row) {
    return FollowUpItem(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      graduateId: row['graduate_id'] as String,
      detail: nullableString(row, 'detail'),
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      scheduledAt: dateOf(row, 'scheduled_at'),
    );
  }

  String get dateLabel => UrduDates.label(scheduledAt);
}

/// Guidance written by a mentor for a graduate.
class MentorFeedback {
  const MentorFeedback({
    required this.id,
    required this.subject,
    required this.message,
    this.mentorName,
    this.createdAt,
  });

  final String id;
  final String subject;
  final String message;
  final String? mentorName;
  final DateTime? createdAt;

  factory MentorFeedback.fromMap(Map<String, dynamic> row) {
    final Object? mentor = row['profiles'];

    return MentorFeedback(
      id: row['id'] as String,
      subject: (row['subject'] as String?) ?? '',
      message: (row['message'] as String?) ?? '',
      mentorName: mentor is Map<String, dynamic>
          ? nullableString(mentor, 'full_name')
          : null,
      createdAt: dateOf(row, 'created_at'),
    );
  }

  String get dateLabel => UrduDates.label(createdAt);
}
