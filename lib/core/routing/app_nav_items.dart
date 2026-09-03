import 'package:flutter/material.dart';

import '../../shared/widgets/app_bottom_navigation.dart';
import '../constants/app_strings.dart';

/// The bottom navigation destinations of each role.
///
/// All three roles share the same four destinations — ہوم, نوٹیفکیشن,
/// میری پروفائل and اہم لنکس — so the bar means the same thing wherever the
/// reader is. Everything else (کارگزاری, ثبوت, زیرِ رہنمائی, انتظامی حصے) is
/// reached from the dashboard and opens on top with a back button, instead of
/// competing for a slot in the bar.
class AppNavItems {
  const AppNavItems._();

  static const List<AppNavItem> _shared = <AppNavItem>[
    AppNavItem(
      label: AppStrings.navHome,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    AppNavItem(
      label: AppStrings.navNotifications,
      icon: Icons.notifications_none_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    AppNavItem(
      label: AppStrings.navMyProfile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
    ),
    AppNavItem(
      label: AppStrings.navLinks,
      icon: Icons.link_outlined,
      selectedIcon: Icons.link_rounded,
    ),
  ];

  static const List<AppNavItem> graduate = _shared;
  static const List<AppNavItem> mentor = _shared;
  static const List<AppNavItem> admin = _shared;
}
