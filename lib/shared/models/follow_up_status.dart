import 'work_items.dart';

/// Where a فاضل / فاضلہ stands in the follow-up cycle.
///
/// Every field is computed by the database from the configured interval and
/// the کارگزاری actually submitted, so changing the organisation's cycle from
/// three months to one changes this immediately, with no new release.
class FollowUpStatus {
  const FollowUpStatus({
    required this.intervalMonths,
    required this.dueOn,
    required this.daysRemaining,
    required this.isOverdue,
    required this.submittedCount,
    this.lastSubmitted,
  });

  /// The organisation's current cycle, in months.
  final int intervalMonths;

  /// When the next کارگزاری is expected.
  final DateTime? dueOn;

  /// Negative once the date has passed.
  final int daysRemaining;
  final bool isOverdue;

  /// How many کارگزاری have actually been submitted; drafts do not count.
  final int submittedCount;
  final DateTime? lastSubmitted;

  /// True while the end of the cycle is close enough to be worth saying.
  bool get isDueSoon => !isOverdue && daysRemaining <= 7;

  factory FollowUpStatus.fromMap(Map<String, dynamic> row) => FollowUpStatus(
        intervalMonths: intOr(row, 'interval_months', 3),
        dueOn: dateOf(row, 'due_on'),
        daysRemaining: intOr(row, 'days_remaining'),
        isOverdue: row['is_overdue'] == true,
        submittedCount: intOr(row, 'submitted_count'),
        lastSubmitted: dateOf(row, 'last_submitted'),
      );
}

/// The full record of one practical activity, as the brief lists it.
///
/// Grouped into one object so the repository does not grow a dozen loose
/// parameters, and so a screen can pass exactly what the participant filled in
/// without the caller having to remember an order.
class KarGuzariDetails {
  const KarGuzariDetails({
    this.activityType,
    this.activityDate,
    this.location,
    this.organisation,
    this.beneficiaries,
    this.learningApplied,
    this.impact,
    this.results,
    this.challenges,
    this.futurePlan,
  });

  /// Workshop, class, webinar, seminar and so on — the participant's own word
  /// for what they did, rather than a fixed list they must squeeze into.
  final String? activityType;
  final DateTime? activityDate;
  final String? location;

  /// The institution or society the work was done with.
  final String? organisation;

  /// How many people it reached, where that is meaningful.
  final int? beneficiaries;

  /// What they put into practice from the course.
  final String? learningApplied;

  /// The practical change it produced.
  final String? impact;
  final String? results;
  final String? challenges;
  final String? futurePlan;

  /// Only the fields that were filled in, so a blank box never overwrites a
  /// stored value with an empty string.
  Map<String, dynamic> toColumns() {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();

    return <String, dynamic>{
      if (clean(activityType) != null) 'activity_type': clean(activityType),
      if (activityDate != null)
        'activity_date': activityDate!.toIso8601String().substring(0, 10),
      if (clean(location) != null) 'location': clean(location),
      if (clean(organisation) != null) 'organisation': clean(organisation),
      if (beneficiaries != null) 'beneficiaries': beneficiaries,
      if (clean(learningApplied) != null)
        'learning_applied': clean(learningApplied),
      if (clean(impact) != null) 'impact': clean(impact),
      if (clean(results) != null) 'results': clean(results),
      if (clean(challenges) != null) 'challenges': clean(challenges),
      if (clean(futurePlan) != null) 'future_plan': clean(futurePlan),
    };
  }
}
