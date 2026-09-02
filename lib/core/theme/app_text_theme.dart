import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised Urdu-first typography.
///
/// Urdu script needs noticeably more vertical breathing room than Latin script,
/// otherwise descenders and diacritics are clipped. Every style below therefore
/// carries a generous [TextStyle.height].
///
/// No font file is bundled in this phase, so the application asks the platform
/// for the best available Urdu face through [urduFontFallback]. When a licensed
/// Nastaliq font is added later, declare it in `pubspec.yaml` and set
/// [preferredFontFamily]; nothing else in the application has to change.
class AppTextTheme {
  const AppTextTheme._();

  /// Bundled font family name. Left null until a font asset is added.
  static const String? preferredFontFamily = null;

  /// Ordered list of Urdu capable faces to try before the platform default.
  static const List<String> urduFontFallback = <String>[
    'Noto Nastaliq Urdu',
    'Jameel Noori Nastaleeq',
    'Alvi Nastaleeq',
    'Noto Naskh Arabic',
    'Segoe UI',
    'Arial',
  ];

  /// Line height multipliers tuned for Urdu.
  static const double _displayHeight = 1.6;
  static const double _titleHeight = 1.7;
  static const double _bodyHeight = 1.9;
  static const double _labelHeight = 1.5;

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required double height,
    required Color color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: preferredFontFamily,
      fontFamilyFallback: urduFontFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      // Urdu joins its letters, so extra tracking damages the word shape.
      letterSpacing: letterSpacing ?? 0,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// The application text theme, consumed by [ThemeData].
  static TextTheme get textTheme => TextTheme(
        displayLarge: _style(
          size: 34,
          weight: FontWeight.w700,
          height: _displayHeight,
          color: AppColors.textHeading,
        ),
        displayMedium: _style(
          size: 30,
          weight: FontWeight.w700,
          height: _displayHeight,
          color: AppColors.textHeading,
        ),
        displaySmall: _style(
          size: 26,
          weight: FontWeight.w700,
          height: _displayHeight,
          color: AppColors.textHeading,
        ),
        headlineLarge: _style(
          size: 24,
          weight: FontWeight.w700,
          height: _titleHeight,
          color: AppColors.textHeading,
        ),
        headlineMedium: _style(
          size: 21,
          weight: FontWeight.w700,
          height: _titleHeight,
          color: AppColors.textHeading,
        ),
        headlineSmall: _style(
          size: 19,
          weight: FontWeight.w700,
          height: _titleHeight,
          color: AppColors.textHeading,
        ),
        titleLarge: _style(
          size: 18,
          weight: FontWeight.w700,
          height: _titleHeight,
          color: AppColors.textPrimary,
        ),
        titleMedium: _style(
          size: 16,
          weight: FontWeight.w600,
          height: _titleHeight,
          color: AppColors.textPrimary,
        ),
        titleSmall: _style(
          size: 15,
          weight: FontWeight.w600,
          height: _titleHeight,
          color: AppColors.textPrimary,
        ),
        bodyLarge: _style(
          size: 16,
          weight: FontWeight.w400,
          height: _bodyHeight,
          color: AppColors.textPrimary,
        ),
        bodyMedium: _style(
          size: 15,
          weight: FontWeight.w400,
          height: _bodyHeight,
          color: AppColors.textSecondary,
        ),
        bodySmall: _style(
          size: 13,
          weight: FontWeight.w400,
          height: _bodyHeight,
          color: AppColors.textSecondary,
        ),
        labelLarge: _style(
          size: 15,
          weight: FontWeight.w600,
          height: _labelHeight,
          color: AppColors.textPrimary,
        ),
        labelMedium: _style(
          size: 13,
          weight: FontWeight.w600,
          height: _labelHeight,
          color: AppColors.textSecondary,
        ),
        labelSmall: _style(
          size: 12,
          weight: FontWeight.w500,
          height: _labelHeight,
          color: AppColors.textLight,
        ),
      );

  /// Style used for large numeric values inside statistic cards.
  ///
  /// Digits read better without the tall Urdu line height, so this style opts
  /// out of it deliberately.
  static TextStyle statValue(Color color) => _style(
        size: 26,
        weight: FontWeight.w700,
        height: 1.2,
        color: color,
      );

  /// Style for the brand mark on the welcome screen.
  static TextStyle brandTitle(Color color) => _style(
        size: 30,
        weight: FontWeight.w700,
        height: 1.6,
        color: color,
      );
}
