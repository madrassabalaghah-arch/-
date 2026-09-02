import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_theme.dart';

/// Assembles the single Material 3 theme used by every screen.
///
/// Screens must not build their own visual style. They read colours, spacing,
/// radii and typography from this theme and from the token classes so all three
/// dashboards belong to one visual brand.
class AppTheme {
  const AppTheme._();

  /// Brand colour scheme. Seeded for correct Material 3 tonal relationships,
  /// then overridden so the official palette is reproduced exactly.
  static final ColorScheme colorScheme =
      ColorScheme.fromSeed(seedColor: AppColors.primaryGreen).copyWith(
    brightness: Brightness.light,
    primary: AppColors.primaryGreen,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.greenTint,
    onPrimaryContainer: AppColors.darkGreen,
    secondary: AppColors.gold,
    onSecondary: AppColors.darkGreen,
    secondaryContainer: AppColors.goldTint,
    onSecondaryContainer: AppColors.earthBrown,
    tertiary: AppColors.tealGreen,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.greenTint,
    onTertiaryContainer: AppColors.darkGreen,
    surface: AppColors.white,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.surfaceSoft,
    surfaceContainer: AppColors.cream,
    surfaceContainerHigh: AppColors.cream,
    surfaceContainerHighest: AppColors.lightGray,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.lightGray,
    outlineVariant: AppColors.lightGray,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorSurface,
    onErrorContainer: AppColors.error,
    shadow: AppColors.shadow,
  );

  /// The application theme.
  static ThemeData get light {
    final TextTheme textTheme = AppTextTheme.textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,

      // ---------------------------------------------------------------
      // App bar: one brand colour everywhere, never a random tone.
      // ---------------------------------------------------------------
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.white, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.white, size: 22),
      ),

      // ---------------------------------------------------------------
      // Cards: white surface, soft border, subtle shadow.
      // ---------------------------------------------------------------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: AppSpacing.lg,
      ),

      // ---------------------------------------------------------------
      // Buttons
      // ---------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.lightGray,
          disabledForegroundColor: AppColors.disabled,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: AppColors.white),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          backgroundColor: AppColors.white,
          disabledForegroundColor: AppColors.disabled,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          side: const BorderSide(color: AppColors.primaryGreen, width: 1.4),
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.primaryGreen,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: textTheme.labelMedium?.copyWith(
            color: AppColors.primaryGreen,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
        ),
      ),

      // ---------------------------------------------------------------
      // Forms: white field, soft border, green focus, clear error.
      // ---------------------------------------------------------------
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.primaryGreen,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.radiusMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),

      // ---------------------------------------------------------------
      // Navigation
      // ---------------------------------------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.greenTint,
        elevation: 0,
        // Urdu labels carry descenders and a tall line box, so the bar needs
        // more height than the Material default sizing assumes.
        height: 78,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusPill,
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryGreen
                : AppColors.gray,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) =>
              (textTheme.labelSmall ?? const TextStyle()).copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryGreen
                : AppColors.gray,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),

      // ---------------------------------------------------------------
      // Surfaces
      // ---------------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.lightGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkGreen,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.greenTint,
        side: BorderSide.none,
        labelStyle: textTheme.labelSmall?.copyWith(
          color: AppColors.primaryGreen,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusPill),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        iconColor: AppColors.primaryGreen,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
        linearTrackColor: AppColors.lightGray,
        circularTrackColor: AppColors.lightGray,
        linearMinHeight: 10,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryGreen, size: 22),
    );
  }
}
