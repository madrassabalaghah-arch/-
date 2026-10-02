// Tests for the Supabase-backed application.
//
// These run entirely signed out, which is exactly the state that matters most
// for security: they prove that a visitor with no session cannot reach any
// protected screen, and that the authentication surface is real and in Urdu.
//
// No mock data exists in the application any more, so there is nothing to
// stub — an unauthenticated client simply has no rows it may read.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:madrassa_graduate_app/app.dart';
import 'package:madrassa_graduate_app/core/config/app_config.dart';
import 'package:madrassa_graduate_app/features/admin/presentation/workshop/participant_file.dart';
import 'package:madrassa_graduate_app/features/auth/data/course_repository.dart';
import 'package:madrassa_graduate_app/core/config/supabase_config.dart';
import 'package:madrassa_graduate_app/core/constants/app_strings.dart';
import 'package:madrassa_graduate_app/core/routing/app_nav_items.dart';
import 'package:madrassa_graduate_app/core/routing/app_router.dart';
import 'package:madrassa_graduate_app/core/routing/app_routes.dart';
import 'package:madrassa_graduate_app/core/theme/app_colors.dart';
import 'package:madrassa_graduate_app/features/auth/application/auth_providers.dart';
import 'package:madrassa_graduate_app/features/auth/data/auth_repository.dart';
import 'package:madrassa_graduate_app/shared/widgets/widgets.dart';
import 'package:madrassa_graduate_app/shared/models/models.dart';
import 'package:madrassa_graduate_app/shared/providers/data_providers.dart';


/// An authenticated account whose profile and role reads fail, which is what
/// losing connectivity looks like from inside the app: the Supabase SDK still
/// holds the persisted session, but every query throws.
class _OfflineAuthRepository extends AuthRepository {
  _OfflineAuthRepository(super.client);

  /// Flipped on once the first load has succeeded, so a test can go offline
  /// after a good session exists.
  bool offline = false;

  static const User _user = User(
    id: '11111111-1111-1111-1111-111111111111',
    appMetadata: <String, dynamic>{},
    userMetadata: <String, dynamic>{},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00.000Z',
    email: 'someone@example.org',
  );

  @override
  User? get currentUser => _user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream<AuthState>.empty();

  @override
  Future<AppUser?> loadProfile(String userId) async {
    if (offline) {
      throw const SocketException('offline');
    }
    return const AppUser(id: '11111111-1111-1111-1111-111111111111',
        fullName: 'محمد عثمان');
  }

  @override
  Future<List<AppRole>> loadRoles(String userId) async {
    if (offline) {
      throw const SocketException('offline');
    }
    return const <AppRole>[AppRole.graduate];
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const ProviderScope(child: MadrassaApp()));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // The Supabase SDK reaches for shared_preferences during start-up, and
    // no platform implementation exists under flutter test. Answering the
    // channel with an empty store keeps initialisation on the happy path.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall call) async =>
          call.method == 'getAll' ? <String, Object>{} : null,
    );

    // EmptyLocalStorage keeps every test signed out and stops the SDK from
    // persisting a session between tests.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
  });

  testWidgets('welcome screen shows the Urdu greeting and continue action',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    expect(find.text(AppStrings.welcome), findsOneWidget);
    expect(find.text(AppStrings.continueAction), findsOneWidget);
  });

  testWidgets('the whole application is laid out right to left',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    final Directionality directionality = tester.widget<Directionality>(
      find
          .descendant(
            of: find.byType(MadrassaApp),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('the official cream and green identity is applied',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    final ThemeData theme =
        Theme.of(tester.element(find.text(AppStrings.welcome)));
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColors.primaryGreen);
    expect(theme.colorScheme.secondary, AppColors.gold);
    expect(theme.scaffoldBackgroundColor, AppColors.cream);
  });

  testWidgets('continue opens the real sign in screen, not a role picker',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.signInTitle), findsOneWidget);
    expect(find.text(AppStrings.labelEmail), findsOneWidget);
    expect(find.text(AppStrings.labelPassword), findsOneWidget);

    // The demo role picker is gone: no role is selectable without signing in.
    for (final AppRole role in AppRole.values) {
      expect(find.text(role.urduTitle), findsNothing);
    }
  });

  testWidgets('registration asks for the course record and the profile facts',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.signUp).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.signUpTitle), findsOneWidget);
    expect(find.text(AppStrings.publicSignupClosed), findsOneWidget);

    // Step one is the three identifying fields and nothing else: the profile
    // questions are not asked until the register has matched the record.
    expect(find.text(AppStrings.registrationNumber), findsOneWidget);
    expect(find.text(AppStrings.participantName), findsOneWidget);
    expect(find.text(AppStrings.coursePeriod), findsOneWidget);
    expect(find.text(AppStrings.selectCategory), findsNothing,
        reason: 'category must wait until the record has matched');
    expect(find.text(AppStrings.labelPassword), findsNothing,
        reason: 'a password must not be asked for before verification');

    // An empty form is refused rather than sent to the server.
    final Finder submit =
        find.widgetWithText(PrimaryButton, AppStrings.verifyNumber);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.regRequired), findsWidgets);
  });

  testWidgets('protected routes are unreachable without a session',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    const List<String> protected = <String>[
      AppRoutes.graduateDashboard,
      AppRoutes.graduateReports,
      AppRoutes.graduateProfile,
      AppRoutes.mentorDashboard,
      AppRoutes.mentorGraduates,
      AppRoutes.adminDashboard,
      AppRoutes.adminGraduates,
      AppRoutes.adminReports,
      AppRoutes.adminStaff,
      AppRoutes.adminAddStaff,
    ];

    for (final String route in protected) {
      // Deep-linking straight at a protected route must land on sign in.
      // The router is read from the container because MadrassaApp sits above
      // the GoRouter, so context.go has nothing to look up.
      final ProviderContainer container =
          ProviderScope.containerOf(tester.element(find.byType(MadrassaApp)));
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.signInTitle),
        findsOneWidget,
        reason: '$route should have redirected to the sign in screen',
      );
    }
  });

  testWidgets('the authentication screens can be backed out of',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    // Welcome -> sign in, then back to welcome.
    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signInTitle), findsOneWidget);

    expect(find.byType(BackButton), findsOneWidget,
        reason: 'sign in needs a way back to the welcome screen');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcome), findsOneWidget);

    // Welcome -> sign in -> sign up, then back to sign in.
    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.signUp).last);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signUpTitle), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signInTitle), findsOneWidget);
  });

  test('every role shares the same four navigation destinations', () {
    const List<String> expected = <String>[
      AppStrings.navHome,
      AppStrings.navNotifications,
      AppStrings.navMyProfile,
      AppStrings.navLinks,
    ];

    for (final MapEntry<String, List<AppNavItem>> role
        in <String, List<AppNavItem>>{
      'graduate': AppNavItems.graduate,
      'mentor': AppNavItems.mentor,
      'admin': AppNavItems.admin,
    }.entries) {
      expect(
        role.value.map((AppNavItem item) => item.label).toList(),
        expected,
        reason:
            '${role.key} must show ہوم / نوٹیفکیشن / میری پروفائل / اہم لنکس',
      );
    }
  });

  test('screens taken out of the bottom bar still open with a back button', () {
    // Each of these used to be a navigation branch. A branch is switched with
    // `go` and leaves nothing to go back to, so once they are reached from the
    // dashboard instead they have to be pushed.
    for (final String path in <String>[
      AppRoutes.graduateReports,
      AppRoutes.graduateEvidence,
      AppRoutes.mentorGraduates,
      AppRoutes.mentorReviews,
      AppRoutes.mentorEvidence,
      AppRoutes.adminGraduates,
      AppRoutes.adminMentors,
    ]) {
      expect(AppRoutes.isFullScreen(path), isTrue,
          reason: '$path is opened from a dashboard and needs a back button');
    }

    // The four destinations of the bar are the opposite case: they must stay
    // branches, or the bar would stack on top of itself.
    for (final String path in <String>[
      AppRoutes.graduateDashboard,
      AppRoutes.graduateNotifications,
      AppRoutes.graduateProfile,
      AppRoutes.graduateLinks,
      AppRoutes.mentorDashboard,
      AppRoutes.mentorNotifications,
      AppRoutes.mentorProfile,
      AppRoutes.mentorLinks,
      AppRoutes.adminDashboard,
      AppRoutes.adminNotifications,
      AppRoutes.adminProfile,
      AppRoutes.adminLinks,
    ]) {
      expect(AppRoutes.isFullScreen(path), isFalse,
          reason: '$path is a bottom navigation destination');
    }
  });

  test('the official name and tagline are exact', () {
    expect(AppConfig.appNameUrdu, 'مدرسہ تربیت ایپ');
    expect(AppConfig.appTaglineUrdu, 'علم سے عمل، عمل سے اثر تک');
  });

  test('the email link comes back to the application, not to localhost', () {
    // A confirmation or recovery link is only useful if Supabase redirects to
    // a scheme the phone hands back to this application. Three files have to
    // agree on that scheme — if they drift, the reader is told the site
    // cannot be reached and the account looks unconfirmed.
    expect(AppConfig.authRedirectUrl,
        '${AppConfig.authRedirectScheme}://${AppConfig.authRedirectHost}');
    expect(AppConfig.authRedirectUrl.startsWith('http'), isFalse,
        reason: 'an http redirect is what produced the localhost failure');

    final String manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:scheme="${AppConfig.authRedirectScheme}"'));
    expect(manifest, contains('android:host="${AppConfig.authRedirectHost}"'));
    expect(manifest, contains('android.intent.category.BROWSABLE'),
        reason: 'without BROWSABLE Android will not hand a link to the app');

    final String plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('<string>${AppConfig.authRedirectScheme}</string>'));

    // The address is confirmed by opening the link, never by writing to the
    // account, so nothing in the application may set these columns.
    for (final String column in <String>['email_confirmed_at', 'confirmed_at']) {
      for (final FileSystemEntity entity
          in Directory('lib').listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          expect(entity.readAsStringSync(), isNot(contains(column)),
              reason: '${entity.path} writes or reads $column');
        }
      }
    }
  });

  test('فاضل is written before فاضلہ, and no greeting survives', () {
    // Spec order: فاضل first, فاضلہ second, everywhere the two appear together.
    for (final String text in <String>[
      AppStrings.graduates,
      AppStrings.totalGraduates,
      AppStrings.activeGraduates,
      AppStrings.myGraduates,
      AppStrings.graduateManagement,
      AppStrings.hintSearchGraduate,
      AppRole.graduate.urduTitle,
    ]) {
      expect(text.contains('فاضلہ / فاضل'), isFalse,
          reason: '"$text" still puts فاضلہ first');
      expect(text.contains('فاضل'), isTrue);
    }
  });

  testWidgets('the password can be revealed without losing what was typed',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();

    // The greeting must be gone from every screen that used to carry it.
    expect(find.textContaining('السلام'), findsNothing);

    final Finder password = find.ancestor(
      of: find.text(AppStrings.labelPassword),
      matching: find.byType(Column),
    );
    expect(password, findsWidgets);

    await tester.enterText(
        find.byType(TextFormField).last, 'qwertyui123');
    await tester.pump();

    TextField field() => tester.widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField).last,
          matching: find.byType(TextField),
        ));

    expect(field().obscureText, isTrue,
        reason: 'the password must start hidden');

    await tester.tap(find.byIcon(Icons.visibility_outlined).last);
    await tester.pumpAndSettle();

    expect(field().obscureText, isFalse, reason: 'the eye must reveal it');
    expect(find.text('qwertyui123'), findsOneWidget,
        reason: 'revealing must not clear the entered password');

    await tester.tap(find.byIcon(Icons.visibility_off_outlined).last);
    await tester.pumpAndSettle();
    expect(field().obscureText, isTrue, reason: 'tapping again must hide it');
  });

  test('losing the connection keeps the session instead of signing out', () async {
    final _OfflineAuthRepository repository =
        _OfflineAuthRepository(Supabase.instance.client);
    final ProviderContainer container = ProviderContainer(
      // The element type is inferred: riverpod's Override is not exported
      // from flutter_riverpod, so it cannot be written out here.
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // A good load first, so there is a session to lose.
    final AppSession? online = await container.read(appSessionProvider.future);
    expect(online, isNotNull);
    expect(online!.roles, <AppRole>[AppRole.graduate]);
    expect(online.isStale, isFalse);

    // Now the network goes away and the session is refreshed.
    repository.offline = true;
    await container.read(appSessionProvider.notifier).refresh();

    final AsyncValue<AppSession?> after = container.read(appSessionProvider);
    expect(after.hasError, isFalse,
        reason: 'a network failure must not become an authentication error');

    final AppSession? offline = after.value;
    expect(offline, isNotNull,
        reason: 'the user must still be signed in while offline');
    expect(offline!.isStale, isTrue,
        reason: 'the values are the previous load, and must say so');
    expect(offline.roles, <AppRole>[AppRole.graduate],
        reason: 'the role must survive, or routing would send them to noRole');
  });

  test('the organisation own column headings are what the importer reads', () {
    // The organisation's file, saved by Excel as "CSV UTF-8": a leading BOM,
    // CRLF endings, Urdu headings, and a quoted name containing a comma.
    const String csv = '\ufeff'
        'رقمِ تسجیل,نام مع ولدیت,داخلہ ماہ,فراغت ماہ\r\n'
        'MD-2026/001,محمد عثمان بن عبداللہ,مارچ 2024,جون 2024\r\n'
        'MD-2026/002,عائشہ صدیقہ بنت کریم,مارچ 2024,جون 2024\r\n'
        'MD-2026/001,دوبارہ وہی نمبر,مارچ 2024,جون 2024\r\n'
        ',بغیر نمبر,مارچ 2024,جون 2024\r\n'
        'MD-2026/004,"خان, محمد",مارچ 2024,جون 2024\r\n';

    final List<List<String>> table =
        ParticipantFile.read(Uint8List.fromList(utf8.encode(csv)), 'list.csv');
    final ({List<CandidateRow> rows, bool missingColumns}) parsed =
        ParticipantFile.toCandidates(table);

    expect(parsed.missingColumns, isFalse,
        reason: 'the Urdu headings must be recognised, BOM and all');
    expect(parsed.rows.length, 5);

    final List<CandidateRow> good =
        parsed.rows.where((CandidateRow r) => r.isValid).toList();
    expect(good.length, 3);

    expect(good.first.registrationNumber, 'MD-2026/001');
    expect(good.first.fullName, 'محمد عثمان بن عبداللہ');
    expect(good.first.courseStartDate, 'مارچ 2024');
    expect(good.first.courseCompletionDate, 'جون 2024');

    // A repeat of a number already seen in the file is refused, not imported.
    expect(parsed.rows[2].problem, CandidateProblem.duplicateInFile);
    // A row with no رقمِ تسجیل is refused.
    expect(parsed.rows[3].problem, CandidateProblem.missingNumber);
    // A quoted field keeps its comma instead of splitting into two columns.
    expect(good.last.fullName, 'خان, محمد');
  });

  testWidgets('an invited mentor or administrator signs up with a code',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();

    final Finder link = find.text(AppStrings.staffSignUpLink);
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.staffSignUpTitle), findsOneWidget);
    expect(find.text(AppStrings.labelEmail), findsOneWidget);
    expect(find.text(AppStrings.inviteCode), findsOneWidget);
    expect(find.text(AppStrings.registrationNumber), findsNothing,
        reason: 'invited staff are not on the course register');
    expect(find.text(AppStrings.labelPassword), findsNothing,
        reason: 'a password must not be asked for before the invitation matches');

    // The role is the invitation's, so there is nothing here to pick one.
    for (final AppRole role in AppRole.values) {
      expect(find.text(role.urduTitle), findsNothing);
    }

    // An empty form is refused rather than sent to the server.
    final Finder verify =
        find.widgetWithText(PrimaryButton, AppStrings.verifyInvite);
    await tester.ensureVisible(verify);
    await tester.pumpAndSettle();
    await tester.tap(verify);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.validationRequired), findsWidgets);

    // So is a code of the wrong length.
    await tester.enterText(
        find.byType(TextFormField).first, 'someone@example.org');
    await tester.enterText(find.byType(TextFormField).last, 'ABC');
    await tester.tap(verify);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.inviteCodeLength), findsOneWidget);
  });

  test('an invitation code matches however it is typed', () {
    expect(StaffInvite.normaliseCode('abcd-2345'), 'ABCD2345');
    expect(StaffInvite.normaliseCode(' ab cd 23 45 '), 'ABCD2345');
    expect(StaffInvite.formatCode('abcd2345'), 'ABCD-2345');
    // Anything other than eight characters is shown as typed, never padded
    // out into something that looks valid.
    expect(StaffInvite.formatCode('abc'), 'ABC');
  });

  test('an invitation check names the person only when it matched', () {
    final StaffInviteCheck matched = StaffInviteCheck.fromMap(
      <String, dynamic>{
        'valid': true,
        'reason': 'ok',
        'invite_name': 'محمد عثمان',
        'invite_role': 'admin',
      },
    );
    expect(matched.valid, isTrue);
    expect(matched.verdict, StaffInviteVerdict.ok);
    expect(matched.name, 'محمد عثمان');
    expect(matched.role, AppRole.admin);

    final StaffInviteCheck taken = StaffInviteCheck.fromMap(
      <String, dynamic>{
        'valid': false,
        'reason': 'email_registered',
        'invite_name': null,
        'invite_role': null,
      },
    );
    expect(taken.valid, isFalse);
    expect(taken.verdict, StaffInviteVerdict.emailRegistered);
    expect(taken.name, isNull);
    expect(taken.role, isNull);

    // A role this build does not know is not guessed at.
    expect(StaffInvite.fromMap(<String, dynamic>{
      'id': 'i1',
      'full_name': 'محمد عثمان',
      'email': 'someone@example.org',
      'role': 'superuser',
      'code': 'ABCD2345',
    }).role, isNull);
  });

  test('staff screens open with a back button; invited sign-up needs none', () {
    expect(AppRoutes.isFullScreen(AppRoutes.adminStaff), isTrue);
    expect(AppRoutes.isFullScreen(AppRoutes.adminAddStaff), isTrue);
    expect(AppRoutes.publicRoutes, contains(AppRoutes.staffSignUp),
        reason: 'the person signing up has no session yet');
  });

  test('only three roles exist, and nothing points at a guest area', () {
    expect(AppRole.values, <AppRole>[
      AppRole.graduate,
      AppRole.mentor,
      AppRole.admin,
    ]);

    // No route, public or otherwise, leads anywhere called guest.
    for (final String route in <String>[
      ...AppRoutes.publicRoutes,
      ...AppRoutes.fullScreenRoutes,
    ]) {
      expect(route.contains('guest'), isFalse,
          reason: '$route still points at the removed guest area');
    }
  });

  test('each role lands on its own dashboard', () {
    // The router sends an account to homeFor(role); a mentor reaching the
    // graduate area or the no-role screen would start here.
    expect(homeFor(AppRole.mentor), AppRoutes.mentorDashboard);
    expect(homeFor(AppRole.graduate), AppRoutes.graduateDashboard);
    expect(homeFor(AppRole.admin), AppRoutes.adminDashboard);

    // An account holding both lands on the stronger one.
    expect(
      AppRole.highest(const <AppRole>[AppRole.graduate, AppRole.mentor]),
      AppRole.mentor,
    );
  });

  test('کل and فعال are separate figures, counted from different things', () {
    // The row the database function returns.
    final AdminStatistics s = AdminStatistics.fromMap(<String, dynamic>{
      'total_male': 40,
      'total_female': 60,
      'total_unrecorded_gender': 0,
      'total_graduates': 100,
      'active_male': 25,
      'active_female': 35,
      'active_unrecorded': 0,
      'active_graduates': 60,
      'accounts_without_record': 2,
      'mentors': 3,
      'admins': 1,
      'guests': 0,
      'active_assignments': 1,
      'pending_reports': 4,
      'under_review': 2,
      'late_reports': 1,
    });

    // کل is the register: 40 + 60, whether or not those people signed up.
    expect(s.totalMale, 40);
    expect(s.totalFemale, 60);
    expect(s.totalGraduates, 100);

    // فعال is the accounts, and it does not disturb the totals.
    expect(s.activeMale, 25);
    expect(s.activeFemale, 35);
    expect(s.activeGraduates, 60);
    expect(s.totalGraduates, 100);

    // A mentor counts by role. The figure used to come from
    // mentor_assignments, so a mentor with nobody assigned went missing.
    expect(s.mentors, 3);
    expect(s.accountsWithoutRecord, 2);
  });

  test('the register reads جنس only when the file says it plainly', () {
    expect(ParticipantFile.genderFrom('مرد'), 'male');
    expect(ParticipantFile.genderFrom('فاضل'), 'male');
    expect(ParticipantFile.genderFrom('Female'), 'female');
    expect(ParticipantFile.genderFrom('فاضلہ'), 'female');

    // Anything unclear is left unrecorded rather than guessed, because a
    // guess would be counted as a fact in کل فاضل / کل فاضلہ.
    expect(ParticipantFile.genderFrom(''), isNull);
    expect(ParticipantFile.genderFrom('نامعلوم'), isNull);
    expect(ParticipantFile.genderFrom('1'), isNull);
  });

  test('evidence and reviews name the people they belong to', () {
    final EvidenceItem evidence = EvidenceItem.fromMap(<String, dynamic>{
      'id': 'e1',
      'title': 'تصویر',
      'graduate_id': 'g1',
      'storage_path': 'g1/x.jpg',
      'kind': 'image',
      'graduate': <String, dynamic>{
        'full_name': 'صبیحہ پرویز',
        'gender': 'female',
      },
      'report': <String, dynamic>{'title': 'اصلاحی حلقہ'},
    });
    expect(evidence.graduateName, 'صبیحہ پرویز');
    expect(evidence.graduateLabel, 'فاضلہ');
    expect(evidence.reportTitle, 'اصلاحی حلقہ');

    // Without the embed the file is still readable, and simply says nothing
    // it does not know.
    final EvidenceItem bare = EvidenceItem.fromMap(<String, dynamic>{
      'id': 'e2',
      'title': 'دستاویز',
      'graduate_id': 'g2',
      'storage_path': 'g2/y.pdf',
    });
    expect(bare.graduateName, isNull);
    expect(bare.graduateLabel, 'فاضل / فاضلہ');

    final EvaluationItem review = EvaluationItem.fromMap(<String, dynamic>{
      'id': 'v1',
      'report_id': 'r1',
      'graduate_id': 'g1',
      'mentor_id': 'm1',
      'comment': 'بہت خوب',
      'report': <String, dynamic>{'title': 'اصلاحی حلقہ'},
      'mentor': <String, dynamic>{'full_name': 'محمد اسلم'},
      'graduate': <String, dynamic>{'full_name': 'صبیحہ پرویز'},
    });
    expect(review.mentorName, 'محمد اسلم');
    expect(review.graduateName, 'صبیحہ پرویز');
    expect(review.title, 'اصلاحی حلقہ');

    final MentorFeedback feedback = MentorFeedback.fromMap(<String, dynamic>{
      'id': 'f1',
      'subject': 'حوصلہ افزائی',
      'message': 'بہت خوب',
      'report_id': 'r1',
      'mentor': <String, dynamic>{'full_name': 'محمد اسلم'},
      'graduate': <String, dynamic>{'full_name': 'صبیحہ پرویز'},
      'report': <String, dynamic>{'title': 'اصلاحی حلقہ'},
    });
    expect(feedback.mentorName, 'محمد اسلم');
    expect(feedback.graduateName, 'صبیحہ پرویز');
    expect(feedback.reportTitle, 'اصلاحی حلقہ');
    expect(feedback.reportId, 'r1');
  });

  test('a summary card counts exactly the rows its list will show', () {
    const ReportCategory teaching = ReportCategory(
      id: 'c1', key: 'teaching', groupKey: 'institutional',
      groupTitle: 'ادارتی خدمات', title: 'تدریس');
    const ReportCategory counselling = ReportCategory(
      id: 'c2', key: 'counselling', groupKey: ReportCategory.socialGroup,
      groupTitle: 'معاشرتی و دینی خدمات', title: 'کونسلنگ');
    const List<ReportCategory> categories = <ReportCategory>[teaching, counselling];

    ReportItem report(String id, AppStatus status, String? category) =>
        ReportItem(id: id, title: id, graduateId: 'g', status: status,
            categoryId: category);

    final List<ReportItem> reports = <ReportItem>[
      report('draft-teaching', AppStatus.draft, 'c1'),
      report('done-counselling', AppStatus.completed, 'c2'),
      report('open-counselling', AppStatus.submitted, 'c2'),
      report('done-uncategorised', AppStatus.completed, null),
    ];

    List<String> ids(List<ReportItem> r) => r.map((ReportItem x) => x.id).toList();

    expect(ids(filterKarGuzari(reports, categories)), hasLength(4),
        reason: 'مجموعی کارگزاریاں counts every کارگزاری');
    expect(ids(filterKarGuzari(reports, categories, filter: KarGuzariFilter.social)),
        <String>['done-counselling', 'open-counselling'],
        reason: 'only the social group counts as معاشرتی و اصلاحی');
    expect(ids(filterKarGuzari(reports, categories, filter: KarGuzariFilter.completed)),
        <String>['done-counselling', 'done-uncategorised'],
        reason: 'مکمل شدہ پروجیکٹس is decided by review status, not category');
    expect(ids(filterKarGuzari(reports, categories, categoryKey: 'teaching')),
        <String>['draft-teaching'],
        reason: 'a quick access category narrows to that category alone');
  });
}
