import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import 'app_status.dart';
import 'follow_up_status.dart';
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
    this.graduateFatherName,
    this.graduateGender,
    this.activityType,
    this.status = AppStatus.draft,
    this.submittedAt,
    this.dueAt,
    this.createdAt,
    this.categoryId,
    this.sharedAt,
    this.details = const KarGuzariDetails(),
  });

  /// The fuller record — impact, results, beneficiaries and so on — so a
  /// reviewer reads what was actually done, not only the title.
  final KarGuzariDetails details;

  final String id;
  final String title;
  final String graduateId;

  /// The `report_categories` row this کارگزاری was filed under, if any.
  final String? categoryId;
  final String? summary;

  /// When the graduate chose to show this کارگزاری on the کمیونٹی بورڈ.
  /// Null means it is private, which is how every کارگزاری starts.
  final DateTime? sharedAt;
  final String? graduateName;

  /// ولدیت and جنس of the owner, embedded beside the name so a list can read
  /// «فاضل محمد اکرم» rather than guessing which it is.
  final String? graduateFatherName;
  final String? graduateGender;

  final String? activityType;
  final AppStatus status;
  final DateTime? submittedAt;
  final DateTime? dueAt;
  final DateTime? createdAt;

  /// فاضل or فاضلہ, from the owner's جنس, or the neutral word when جنس is
  /// not recorded — which it is not for most of the register.
  String get graduateLabel {
    switch (graduateGender) {
      case 'male':
        return AppStrings.maleLabel;
      case 'female':
        return AppStrings.femaleLabel;
      default:
        return AppStrings.graduateLabel;
    }
  }

  /// The owner, named. Built from the parts that exist, so a کارگزاری whose
  /// owner could not be embedded reads as «نام ریکارڈ میں نہیں» instead of
  /// printing the literal text "null".
  String get graduateLine {
    final String name = (graduateName ?? '').trim();
    if (name.isEmpty) {
      return AppStrings.nameNotRecorded;
    }
    final String father = (graduateFatherName ?? '').trim();
    return father.isEmpty ? name : '$name $father';
  }

  /// Both halves of defect 1.3 live here. The query must embed the owner's
  /// profile under the `graduate` alias, and nothing may interpolate
  /// [graduateName] straight into a sentence — a realtime stream cannot
  /// carry an embedded row, so it is null there by construction.
  factory ReportItem.fromMap(Map<String, dynamic> row) {
    final Object? profile = row['graduate'] ?? row['profiles'];
    final Object? activity = row['activities'];

    return ReportItem(
      id: row['id'] as String,
      title: (row['title'] as String?) ?? '',
      graduateId: row['graduate_id'] as String,
      summary: nullableString(row, 'summary'),
      graduateName: profile is Map<String, dynamic>
          ? nullableString(profile, 'full_name')
          : null,
      graduateFatherName: profile is Map<String, dynamic>
          ? nullableString(profile, 'father_name')
          : null,
      graduateGender: profile is Map<String, dynamic>
          ? nullableString(profile, 'gender')
          : null,
      activityType: activity is Map<String, dynamic>
          ? nullableString(activity, 'title')
          : null,
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      submittedAt: dateOf(row, 'submitted_at'),
      dueAt: dateOf(row, 'due_at'),
      createdAt: dateOf(row, 'created_at'),
      categoryId: nullableString(row, 'category_id'),
      sharedAt: dateOf(row, 'shared_at'),
      details: KarGuzariDetails.fromMap(row),
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
    this.graduateName,
    this.graduateGender,
    this.reportTitle,
  });

  /// What the reviewer said, shown to the graduate beside the verdict.
  final String? reviewNote;

  final String id;
  final String title;
  final String graduateId;

  /// Who submitted it, and the کارگزاری it belongs to. Filled in for the
  /// mentor and administrator lists, where a file without its owner is not
  /// evidence of anything. Null on a graduate's own list, which is all
  /// theirs already.
  final String? graduateName;

  /// 'male' or 'female' from the owner's profile, so the label reads فاضل
  /// or فاضلہ rather than guessing one of them.
  final String? graduateGender;
  final String? reportTitle;

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
    // Present only when the query embedded them; the graduate's own list
    // does not, because every row there is theirs.
    final Object? graduate = row['graduate'] ?? row['profiles'];
    final Object? report = row['report'] ?? row['reports'];

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
      graduateName: graduate is Map<String, dynamic>
          ? nullableString(graduate, 'full_name')
          : null,
      graduateGender: graduate is Map<String, dynamic>
          ? nullableString(graduate, 'gender')
          : null,
      reportTitle:
          report is Map<String, dynamic> ? nullableString(report, 'title') : null,
    );
  }

  /// فاضل or فاضلہ for the owner, or the pair when the profile does not say.
  String get graduateLabel {
    switch (graduateGender) {
      case 'male':
        return 'فاضل';
      case 'female':
        return 'فاضلہ';
      default:
        return 'فاضل / فاضلہ';
    }
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
    this.mentorName,
    this.graduateName,
    this.comment,
    this.status = AppStatus.underReview,
    this.createdAt,
  });

  final String id;
  final String reportId;
  final String graduateId;
  final String mentorId;

  /// The کارگزاری this review is about.
  final String? title;

  /// Who wrote the review, and about whom. A review that cannot name both
  /// tells nobody anything, so every screen that shows one asks for them.
  final String? mentorName;
  final String? graduateName;
  final String? comment;
  final AppStatus status;
  final DateTime? createdAt;

  factory EvaluationItem.fromMap(Map<String, dynamic> row) {
    final Object? report = row['report'] ?? row['reports'];
    // Two profiles are embedded under names of their own, because a row
    // that simply said "profiles" could not say which side it meant.
    final Object? mentor = row['mentor'] ?? row['profiles'];
    final Object? graduate = row['graduate'];

    return EvaluationItem(
      id: row['id'] as String,
      reportId: row['report_id'] as String,
      graduateId: row['graduate_id'] as String,
      mentorId: row['mentor_id'] as String,
      title: report is Map<String, dynamic>
          ? nullableString(report, 'title')
          : null,
      mentorName: mentor is Map<String, dynamic>
          ? nullableString(mentor, 'full_name')
          : null,
      graduateName: graduate is Map<String, dynamic>
          ? nullableString(graduate, 'full_name')
          : null,
      comment: nullableString(row, 'comment'),
      status: AppStatusX.fromDb(nullableString(row, 'status')),
      createdAt: dateOf(row, 'created_at'),
    );
  }

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
    this.graduateName,
    this.reportId,
    this.reportTitle,
    this.createdAt,
  });

  final String id;
  final String subject;
  final String message;

  /// The mentor who wrote it. The graduate is told who is speaking to them.
  final String? mentorName;

  /// Who it was written for, and the کارگزاری it followed, when it followed
  /// one. Both are filled in for the administrator's view.
  final String? graduateName;
  final String? reportId;
  final String? reportTitle;
  final DateTime? createdAt;

  factory MentorFeedback.fromMap(Map<String, dynamic> row) {
    final Object? mentor = row['mentor'] ?? row['profiles'];
    final Object? graduate = row['graduate'];
    final Object? report = row['report'] ?? row['reports'];

    return MentorFeedback(
      id: row['id'] as String,
      subject: (row['subject'] as String?) ?? '',
      message: (row['message'] as String?) ?? '',
      mentorName: mentor is Map<String, dynamic>
          ? nullableString(mentor, 'full_name')
          : null,
      graduateName: graduate is Map<String, dynamic>
          ? nullableString(graduate, 'full_name')
          : null,
      reportId: nullableString(row, 'report_id'),
      reportTitle:
          report is Map<String, dynamic> ? nullableString(report, 'title') : null,
      createdAt: dateOf(row, 'created_at'),
    );
  }

  String get dateLabel => UrduDates.label(createdAt);
}
