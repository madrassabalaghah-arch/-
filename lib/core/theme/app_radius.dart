import 'package:flutter/widgets.dart';

/// Centralised corner radius scale.
///
/// The visual language is elegant and minimal, so radii stay moderate.
/// Excessively rounded surfaces are deliberately avoided.
class AppRadius {
  const AppRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));

  /// Rounded bottom corners used by gradient headers. Directional so the shape
  /// mirrors correctly in right-to-left layouts.
  static const BorderRadiusDirectional headerBottom =
      BorderRadiusDirectional.only(
    bottomStart: Radius.circular(xxl),
    bottomEnd: Radius.circular(xxl),
  );

  /// Rounded top corners used by bottom sheets.
  static const BorderRadiusDirectional sheetTop = BorderRadiusDirectional.only(
    topStart: Radius.circular(xl),
    topEnd: Radius.circular(xl),
  );
}
