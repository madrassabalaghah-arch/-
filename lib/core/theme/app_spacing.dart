import 'package:flutter/widgets.dart';

/// Centralised spacing scale.
///
/// Every gap, padding and margin in the application must come from this scale
/// so the vertical rhythm stays consistent across all screens.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Horizontal padding applied to the content of every screen.
  static const double screenHorizontal = lg;

  /// Vertical padding applied to the content of every screen.
  static const double screenVertical = lg;

  /// Standard inner padding of a card.
  static const double cardPadding = lg;

  /// Extra bottom padding so the last card is never hidden behind the
  /// bottom navigation bar.
  static const double bottomSafeArea = huge + xxl;

  /// Directional page padding. Directional insets keep the layout correct in
  /// both right-to-left and left-to-right text directions.
  static const EdgeInsetsDirectional screenPadding =
      EdgeInsetsDirectional.fromSTEB(
    screenHorizontal,
    screenVertical,
    screenHorizontal,
    bottomSafeArea,
  );

  /// Directional padding used inside cards.
  static const EdgeInsetsDirectional cardInsets =
      EdgeInsetsDirectional.all(cardPadding);

  /// Common fixed vertical gaps, exposed as widgets to keep build methods short.
  static const Widget gapXxs = SizedBox(height: xxs);
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);
  static const Widget gapXxxl = SizedBox(height: xxxl);

  /// Common fixed horizontal gaps.
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}
