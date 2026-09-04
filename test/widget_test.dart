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
import 'package:madrassa_graduate_app/shared/models/app_role.dart';
import 'package:madrassa_graduate_app/shared/widgets/widgets.dart';
import 'package:madrassa_graduate_app/shared/models/people.dart';


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

    // Everything the brief asks for on one form: the register's own two
    // fields, then the three the participant answers themselves.
    expect(find.text(AppStrings.registrationNumber), findsOneWidget);
    expect(find.text(AppStrings.participantName), findsOneWidget);
    expect(find.text(AppStrings.selectCategory), findsOneWidget);
    expect(find.text(AppStrings.maleLabel), findsOneWidget);
    expect(find.text(AppStrings.femaleLabel), findsOneWidget);
    expect(find.text(AppStrings.newInstituteName), findsOneWidget);

    // فاضل is offered before فاضلہ. The layout is right to left, so first
    // means further to the right.
    final double male = tester.getTopLeft(find.text(AppStrings.maleLabel)).dx;
    final double female =
        tester.getTopLeft(find.text(AppStrings.femaleLabel)).dx;
    expect(male > female, isTrue,
        reason: 'فاضل must be offered before فاضلہ');

    // An empty form is refused rather than sent to the server.
    final Finder submit = find.widgetWithText(PrimaryButton, AppStrings.signUp);
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
    expect(AppConfig.appNameUrdu, 'کاروان فضلاء مدرسہ ڈاٹ پی کے');
    expect(AppConfig.appTaglineUrdu, 'علم سے عمل، عمل سے اثر تک');
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
}
