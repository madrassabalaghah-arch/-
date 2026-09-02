import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Navigation helpers used by every screen.
extension AppNavigation on BuildContext {
  /// Opens [path] using the behaviour that route is meant to have.
  ///
  /// Bottom navigation branches are switched with `go`, which keeps the bar
  /// visible and preserves each branch's own history. Secondary screens are
  /// pushed, so the app bar shows a back button and the user returns to the
  /// dashboard exactly where they left it.
  void goToRoute(String path) {
    if (AppRoutes.isFullScreen(path)) {
      push<void>(path);
    } else {
      go(path);
    }
  }
}
