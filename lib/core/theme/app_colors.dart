import 'package:flutter/material.dart';

/// The single source of truth for every brand colour in the application.
///
/// Screens and widgets must never hardcode a brand colour. Always reference a
/// token from this class so the visual identity stays consistent everywhere.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Official primary colours
  // ---------------------------------------------------------------------------

  /// Main brand identity: primary buttons, app bars, selected navigation.
  static const Color primaryGreen = Color(0xFF0D6B3E);

  /// Strong headings, high emphasis sections, strong brand surfaces.
  static const Color darkGreen = Color(0xFF074B2A);

  /// Recognition, achievements, awards, milestones, special highlights.
  static const Color gold = Color(0xFFC8A254);

  /// Main application background and calm content areas.
  static const Color cream = Color(0xFFF5F2E6);

  /// Cards, forms, dialogs and elevated content surfaces.
  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Official secondary colours
  // ---------------------------------------------------------------------------

  /// Progress and positive supporting states.
  static const Color tealGreen = Color(0xFF1FA37A);

  /// Secondary positive elements and soft green emphasis.
  static const Color oliveGreen = Color(0xFF7CA16A);

  /// Heritage accents and traditional supporting categories.
  static const Color earthBrown = Color(0xFF8B5E34);

  /// Secondary text, neutral states, disabled elements.
  static const Color gray = Color(0xFF6B7280);

  /// Borders, dividers and soft neutral surfaces.
  static const Color lightGray = Color(0xFFE5E7EB);

  // ---------------------------------------------------------------------------
  // Official text colours
  // ---------------------------------------------------------------------------

  /// Primary heading colour.
  static const Color textHeading = Color(0xFF0D6B3E);

  /// Primary body text.
  static const Color textPrimary = Color(0xFF1F2937);

  /// Secondary body text.
  static const Color textSecondary = Color(0xFF4B5563);

  /// Light / tertiary text, hints and timestamps.
  static const Color textLight = Color(0xFF9CA3AF);

  // ---------------------------------------------------------------------------
  // Gradient end stops, declared here so gradients stay token driven.
  // ---------------------------------------------------------------------------

  /// End stop of the official gold gradient.
  static const Color goldLight = Color(0xFFE2C27A);

  // ---------------------------------------------------------------------------
  // System state tones.
  //
  // These are not brand colours. They exist only so error, warning and success
  // states remain legible, and they are centralised rather than ad hoc.
  // ---------------------------------------------------------------------------

  /// Validation and error state tone.
  static const Color error = Color(0xFFB3261E);

  /// Soft error surface used behind error messages.
  static const Color errorSurface = Color(0xFFFBEAE8);

  /// Attention or delayed state tone, drawn from the heritage brown family.
  static const Color warning = Color(0xFFB07A2E);

  /// Success state tone, aligned with the secondary teal green.
  static const Color success = Color(0xFF1FA37A);

  // ---------------------------------------------------------------------------
  // Derived surfaces and utilities
  // ---------------------------------------------------------------------------

  /// Default application background.
  static const Color background = cream;

  /// Default card and form surface.
  static const Color surface = white;

  /// Soft cream surface used inside white cards for grouped content.
  static const Color surfaceSoft = Color(0xFFFAF8F0);

  /// Standard border for cards, form fields and dividers.
  static const Color border = lightGray;

  /// Disabled foreground.
  static const Color disabled = Color(0xFFB6BBC4);

  /// Base shadow colour. Always used with a low opacity.
  static const Color shadow = Color(0xFF0D2A1C);

  /// Soft green tint used for icon chips and selected list rows.
  static const Color greenTint = Color(0xFFE7F1EC);

  /// Soft gold tint used for recognition chips and highlights.
  static const Color goldTint = Color(0xFFF7EEDC);
}
