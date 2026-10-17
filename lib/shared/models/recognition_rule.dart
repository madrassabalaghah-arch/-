import '../../core/constants/app_strings.dart';
import 'work_items.dart';

/// What a recognition is measured against.
///
/// The keys are the ones `award_earned_recognitions()` understands. They stay
/// in English because the database reads them; the Urdu label beside each is
/// what an administrator actually sees.
enum RecognitionCriterion {
  submittedReports('submitted_reports', AppStrings.criterionSubmitted),
  reviewedReports('reviewed_reports', AppStrings.criterionReviewed),
  onTimeReports('on_time_reports', AppStrings.criterionOnTime),
  evidenceFiles('evidence_files', AppStrings.criterionEvidence);

  const RecognitionCriterion(this.dbValue, this.urduLabel);

  final String dbValue;
  final String urduLabel;

  static RecognitionCriterion? fromDb(String? value) {
    for (final RecognitionCriterion c in RecognitionCriterion.values) {
      if (c.dbValue == value) {
        return c;
      }
    }
    return null;
  }
}

/// One configurable rule for granting a recognition.
///
/// The organisation sets these. Nothing is seeded, so with an empty table no
/// recognition is granted at all, rather than an invented one appearing.
class RecognitionRule {
  const RecognitionRule({
    required this.id,
    required this.title,
    required this.criterion,
    this.detail,
    this.threshold = 1,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String? detail;

  /// Null when the stored criterion is one this build does not know about.
  /// Shown as such rather than silently treated as something else.
  final RecognitionCriterion? criterion;
  final int threshold;
  final bool isActive;

  factory RecognitionRule.fromMap(Map<String, dynamic> row) => RecognitionRule(
        id: row['id'] as String,
        title: (row['title'] as String?) ?? '',
        detail: nullableString(row, 'detail'),
        criterion:
            RecognitionCriterion.fromDb(nullableString(row, 'criterion')),
        threshold: intOr(row, 'threshold', 1),
        isActive: row['is_active'] != false,
      );
}
