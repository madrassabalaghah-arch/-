// Tests for the Supabase-backed application.
//
// These run entirely signed out, which is exactly the state that matters most
// for security: they prove that a visitor with no session cannot reach any
// protected screen, and that the authentication surface is real and in Urdu.
//
// No mock data exists in the application any more, so there is nothing to
// stub — an unauthenticated client simply has no rows it may read.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:madrassa_graduate_app/app.dart';
import 'package:madrassa_graduate_app/core/config/supabase_config.dart';
import 'package:madrassa_graduate_app/core/constants/app_strings.dart';
import 'package:madrassa_graduate_app/core/routing/app_router.dart';
import 'package:madrassa_graduate_app/core/routing/app_routes.dart';
import 'package:madrassa_graduate_app/core/theme/app_colors.dart';
import 'package:madrassa_graduate_app/shared/models/app_role.dart';

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

  testWidgets('sign up is gated behind workshop verification',
      (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.signUp).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.signUpTitle), findsOneWidget);

    // Step one is the registration number and nothing else. Public signup is
    // closed, so the account fields must not be reachable yet.
    expect(find.text(AppStrings.registrationNumber), findsOneWidget);
    expect(find.text(AppStrings.verifyNumber), findsOneWidget);
    expect(find.text(AppStrings.publicSignupClosed), findsOneWidget);

    expect(find.text(AppStrings.labelPassword), findsNothing,
        reason: 'password must not be offered before verification');
    expect(find.text(AppStrings.labelConfirmPassword), findsNothing);
    expect(find.text(AppStrings.labelEmail), findsNothing);

    // Verifying with an empty number is refused in Urdu.
    await tester.tap(find.text(AppStrings.verifyNumber));
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
}
