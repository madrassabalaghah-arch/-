import 'package:flutter/material.dart';

import '../../shared/widgets/app_bottom_navigation.dart';
import '../constants/app_strings.dart';

/// The bottom navigation destinations of each role.
///
/// Declared centrally so the labels stay in Urdu and in step with the routes
/// they belong to.
class AppNavItems {
  const AppNavItems._();

  static const List<AppNavItem> graduate = <AppNavItem>[
    AppNavItem(
      label: AppStrings.navDashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    AppNavItem(
      label: AppStrings.navReports,
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
    ),
    AppNavItem(
      label: AppStrings.navEvidence,
      icon: Icons.folder_open_outlined,
      selectedIcon: Icons.folder_rounded,
    ),
    AppNavItem(
      label: AppStrings.navNotifications,
      icon: Icons.notifications_none_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    AppNavItem(
      label: AppStrings.navProfile,
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  static const List<AppNavItem> mentor = <AppNavItem>[
    AppNavItem(
      label: AppStrings.navDashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    AppNavItem(
      label: AppStrings.navGraduates,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
    ),
    AppNavItem(
      label: AppStrings.navReviews,
      icon: Icons.rate_review_outlined,
      selectedIcon: Icons.rate_review_rounded,
    ),
    AppNavItem(
      label: AppStrings.navEvidence,
      icon: Icons.folder_open_outlined,
      selectedIcon: Icons.folder_rounded,
    ),
  ];

  static const List<AppNavItem> admin = <AppNavItem>[
    AppNavItem(
      label: AppStrings.navDashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    AppNavItem(
      label: AppStrings.graduates,
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
    ),
    AppNavItem(
      label: AppStrings.navMentors,
      icon: Icons.supervisor_account_outlined,
      selectedIcon: Icons.supervisor_account_rounded,
    ),
    AppNavItem(
      label: AppStrings.navNotifications,
      icon: Icons.notifications_none_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
  ];
}
