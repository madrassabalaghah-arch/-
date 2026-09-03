import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/data/admin_repository.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/data/workshop_repository.dart';
import '../../features/graduate/data/graduate_repository.dart';
import '../../features/mentor/data/mentor_repository.dart';
import '../data/reference_repository.dart';
import '../models/models.dart';

final Provider<GraduateRepository> graduateRepositoryProvider =
    Provider<GraduateRepository>(
  (Ref ref) => GraduateRepository(ref.watch(supabaseClientProvider)),
);

final Provider<MentorRepository> mentorRepositoryProvider =
    Provider<MentorRepository>(
  (Ref ref) => MentorRepository(ref.watch(supabaseClientProvider)),
);

final Provider<AdminRepository> adminRepositoryProvider =
    Provider<AdminRepository>(
  (Ref ref) => AdminRepository(ref.watch(supabaseClientProvider)),
);

/// Rebuilds every data provider when the session changes, so signing in as a
/// different user never shows the previous user's cached rows.
void _dependOnSession(Ref ref) => ref.watch(appSessionProvider);

// ---------------------------------------------------------------------------
// Graduate
// ---------------------------------------------------------------------------

/// Reports stream live, so a mentor's status change appears without a refresh.
final StreamProvider<List<ReportItem>> graduateReportsProvider =
    StreamProvider<List<ReportItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).watchReports();
});

final StreamProvider<List<NotificationItem>> graduateNotificationsProvider =
    StreamProvider<List<NotificationItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).watchNotifications();
});

final StreamProvider<List<RecognitionItem>> graduateRecognitionsProvider =
    StreamProvider<List<RecognitionItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).watchRecognitions();
});

final StreamProvider<List<EvidenceItem>> graduateEvidenceProvider =
    StreamProvider<List<EvidenceItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).watchEvidence();
});

final FutureProvider<List<EvaluationItem>> graduateEvaluationsProvider =
    FutureProvider<List<EvaluationItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).evaluations();
});

final FutureProvider<List<ActivityItem>> graduateActivitiesProvider =
    FutureProvider<List<ActivityItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).activities();
});

final FutureProvider<List<TaskItem>> graduateTasksProvider =
    FutureProvider<List<TaskItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).pendingTasks();
});

final FutureProvider<MentorFeedback?> graduateMentorFeedbackProvider =
    FutureProvider<MentorFeedback?>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).latestFeedback();
});

final FutureProvider<FollowUpItem?> graduateFollowUpProvider =
    FutureProvider<FollowUpItem?>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(graduateRepositoryProvider).nextFollowUp();
});

/// The training journey, assembled from the graduate's real activity rows and
/// the stage recorded on their profile.
final FutureProvider<JourneyProgress> graduateJourneyProvider =
    FutureProvider<JourneyProgress>((Ref ref) async {
  final List<ActivityItem> activities =
      await ref.watch(graduateActivitiesProvider.future);
  final List<TaskItem> tasks = await ref.watch(graduateTasksProvider.future);
  final AppUser? profile = ref.watch(currentProfileProvider);

  final int completed =
      activities.fold<int>(0, (int sum, ActivityItem a) => sum + a.completed);
  final int total =
      activities.fold<int>(0, (int sum, ActivityItem a) => sum + a.total);

  return JourneyProgress(
    stageLabel: profile?.stage ?? 'تربیت کا آغاز',
    statusLabel: total == 0
        ? 'ابھی کوئی عملی سرگرمی مقرر نہیں'
        : (completed >= total ? 'تمام مراحل مکمل' : 'تربیت جاری ہے'),
    completedSteps: completed,
    totalSteps: total,
    nextStepLabel:
        tasks.isEmpty ? 'کوئی زیرِ التوا کام نہیں' : tasks.first.title,
  );
});

// ---------------------------------------------------------------------------
// Mentor
// ---------------------------------------------------------------------------

final FutureProvider<List<GraduateSummary>> mentorGraduatesProvider =
    FutureProvider<List<GraduateSummary>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(mentorRepositoryProvider).assignedGraduates();
});

/// Live: a graduate submitting a report reaches the mentor without a refresh.
final StreamProvider<List<ReportItem>> mentorReportsProvider =
    StreamProvider<List<ReportItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(mentorRepositoryProvider).watchIncomingReports();
});

final FutureProvider<List<EvidenceItem>> mentorEvidenceProvider =
    FutureProvider<List<EvidenceItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(mentorRepositoryProvider).evidence();
});

final FutureProvider<List<EvaluationItem>> mentorEvaluationsProvider =
    FutureProvider<List<EvaluationItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(mentorRepositoryProvider).completedEvaluations();
});

final StreamProvider<List<NotificationItem>> mentorNotificationsProvider =
    StreamProvider<List<NotificationItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(mentorRepositoryProvider).watchNotifications();
});

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

final FutureProvider<Map<String, int>> adminStatisticsProvider =
    FutureProvider<Map<String, int>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).statistics();
});

final FutureProvider<List<GraduateSummary>> adminGraduatesProvider =
    FutureProvider<List<GraduateSummary>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).graduates();
});

final FutureProvider<List<MentorSummary>> adminMentorsProvider =
    FutureProvider<List<MentorSummary>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).mentors();
});

final FutureProvider<List<WifaqItem>> adminWifaqsProvider =
    FutureProvider<List<WifaqItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).wifaqs();
});

/// Every wifaq with its institute and فاضل / فاضلہ counts.
final FutureProvider<List<WifaqDirectoryEntry>> adminWifaqDirectoryProvider =
    FutureProvider<List<WifaqDirectoryEntry>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).wifaqDirectory();
});

/// The institutes inside one wifaq, counted. `null` is the unassigned-wifaq
/// bucket at the top of the hierarchy.
final adminInstituteDirectoryProvider =
    FutureProvider.family<List<InstituteDirectoryEntry>, String?>(
        (Ref ref, String? wifaqId) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).instituteDirectory(wifaqId);
});

/// The graduates at one leaf of the wifaq hierarchy.
final adminHierarchyGraduatesProvider = FutureProvider.family<
    List<GraduateSummary>,
    ({String? instituteId, bool includeUnassignedInstitute, String? wifaqId})>(
  (Ref ref, ({String? instituteId, bool includeUnassignedInstitute, String? wifaqId}) target) {
    _dependOnSession(ref);
    return ref.watch(adminRepositoryProvider).graduatesIn(
          instituteId: target.instituteId,
          includeUnassignedInstitute: target.includeUnassignedInstitute,
          wifaqId: target.wifaqId,
        );
  },
);

final FutureProvider<List<CourseItem>> adminCoursesProvider =
    FutureProvider<List<CourseItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).courses();
});

final FutureProvider<List<TaskItem>> adminAssignmentsProvider =
    FutureProvider<List<TaskItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).assignments();
});

final FutureProvider<List<StandardItem>> adminStandardsProvider =
    FutureProvider<List<StandardItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).standards();
});

/// Live: the administrator's report list reflects submissions as they land.
final StreamProvider<List<ReportItem>> adminReportsProvider =
    StreamProvider<List<ReportItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).watchReports();
});

final FutureProvider<List<RecognitionItem>> adminRecognitionsProvider =
    FutureProvider<List<RecognitionItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).recognitions();
});

final StreamProvider<List<NotificationItem>> adminNotificationsProvider =
    StreamProvider<List<NotificationItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).watchNotifications();
});

/// Every account in the system with its current role, for administration.
///
/// Uses allProfiles rather than graduates, because the administration screen
/// must be able to open a mentor or an administrator, not only graduates.
final FutureProvider<List<AdminUserRow>> adminAllUsersProvider =
    FutureProvider<List<AdminUserRow>>((Ref ref) async {
  _dependOnSession(ref);
  final AdminRepository repo = ref.watch(adminRepositoryProvider);
  final List<GraduateSummary> everyone = await repo.allProfiles();
  final Map<String, AppRole> roles = await repo.rolesByUser();

  return everyone
      .map((GraduateSummary g) =>
          AdminUserRow(profile: g, role: roles[g.id]))
      .toList();
});

/// The mentor supervising a given graduate, if any.
final mentorOfProvider =
    FutureProvider.family<MentorSummary?, String>((Ref ref, String graduateId) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).mentorOf(graduateId);
});

/// The graduates supervised by a given mentor.
final graduatesOfProvider = FutureProvider.family<List<GraduateSummary>, String>(
    (Ref ref, String mentorId) {
  _dependOnSession(ref);
  return ref.watch(adminRepositoryProvider).graduatesOf(mentorId);
});

/// A profile paired with the role it currently holds.
class AdminUserRow {
  const AdminUserRow({required this.profile, this.role});

  final GraduateSummary profile;

  /// Null when the account holds the default graduate role.
  final AppRole? role;

  AppRole get effectiveRole => role ?? AppRole.graduate;
}

// ---------------------------------------------------------------------------
// Reference lists
// ---------------------------------------------------------------------------

final Provider<ReferenceRepository> referenceRepositoryProvider =
    Provider<ReferenceRepository>(
  (Ref ref) => ReferenceRepository(ref.watch(supabaseClientProvider)),
);

/// The curated list of wifaqs a user chooses from.
final FutureProvider<List<WifaqItem>> wifaqListProvider =
    FutureProvider<List<WifaqItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(referenceRepositoryProvider).wifaqs();
});

/// Institutes belonging to the selected wifaq.
final instituteListProvider =
    FutureProvider.family<List<InstituteItem>, String?>(
        (Ref ref, String? wifaqId) {
  _dependOnSession(ref);
  return ref.watch(referenceRepositoryProvider).institutes(wifaqId: wifaqId);
});

/// The curated اہم لنکس list every signed-in role can read.
final FutureProvider<List<ImportantLink>> importantLinksProvider =
    FutureProvider<List<ImportantLink>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(referenceRepositoryProvider).importantLinks();
});

/// Every link including retired ones, for the administration view.
final FutureProvider<List<ImportantLink>> allImportantLinksProvider =
    FutureProvider<List<ImportantLink>>((Ref ref) {
  _dependOnSession(ref);
  return ref
      .watch(referenceRepositoryProvider)
      .importantLinks(includeInactive: true);
});

/// The shared activity catalogue a graduate picks from when filing a report.
final FutureProvider<List<ActivityItem>> activityCatalogueProvider =
    FutureProvider<List<ActivityItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(referenceRepositoryProvider).activityCatalogue();
});

/// Every activity including retired ones, for the administration screen.
final FutureProvider<List<ActivityItem>> allActivitiesProvider =
    FutureProvider<List<ActivityItem>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(referenceRepositoryProvider).allActivities();
});

// ---------------------------------------------------------------------------
// Workshop register
// ---------------------------------------------------------------------------

final Provider<WorkshopRepository> workshopRepositoryProvider =
    Provider<WorkshopRepository>(
  (Ref ref) => WorkshopRepository(ref.watch(supabaseClientProvider)),
);

/// The whole register, for administration. Only an administrator can read it;
/// applicants verify a single number through the RPC instead.
final FutureProvider<List<WorkshopParticipant>> workshopParticipantsProvider =
    FutureProvider<List<WorkshopParticipant>>((Ref ref) {
  _dependOnSession(ref);
  return ref.watch(workshopRepositoryProvider).participants();
});
