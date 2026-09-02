import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// The root widget.
///
/// The application is Urdu-first, so Urdu is the only supported locale and the
/// whole widget tree is forced to right-to-left. Forcing the direction here
/// rather than per screen is what makes every card, list, form, dialog and
/// bottom sheet lay out correctly without extra work.
class MadrassaApp extends ConsumerWidget {
  const MadrassaApp({super.key});

  /// The Urdu locale of the interface.
  static const Locale urduLocale = Locale(
    AppConfig.defaultLanguageCode,
    AppConfig.defaultCountryCode,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: urduLocale,
      supportedLocales: const <Locale>[
        urduLocale,
        Locale(AppConfig.defaultLanguageCode),
      ],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          // Right to left everywhere, including dialogs and bottom sheets,
          // which are built above the router and would otherwise inherit the
          // platform direction.
          textDirection: TextDirection.rtl,
          child: MediaQuery.withClampedTextScaling(
            // Urdu already needs tall line boxes. Clamping the upper bound
            // keeps very large system font settings from overflowing cards
            // while still respecting the reader's preference.
            minScaleFactor: 0.9,
            maxScaleFactor: 1.3,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
