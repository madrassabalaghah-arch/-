import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised gradients.
///
/// Only two official gradients exist. They are deliberately limited to high
/// emphasis surfaces so the interface stays calm and premium.
///
/// Both gradients use [AlignmentDirectional] so they flow correctly in the
/// right-to-left Urdu layout.
class AppGradients {
  const AppGradients._();

  /// Official green gradient.
  ///
  /// Allowed usage: important dashboard banners, the main progress section,
  /// selected important cards and special emphasis areas.
  static const LinearGradient green = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[AppColors.primaryGreen, AppColors.tealGreen],
  );

  /// Official gold gradient.
  ///
  /// Allowed usage: recognition, achievements, awards and milestones.
  static const LinearGradient gold = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[AppColors.gold, AppColors.goldLight],
  );

  /// Deep green gradient reserved for administrator surfaces, which carry a
  /// stronger brand tone than the graduate and mentor areas.
  static const LinearGradient darkGreen = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: <Color>[AppColors.darkGreen, AppColors.primaryGreen],
  );
}
