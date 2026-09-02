import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_navigation.dart';

/// The shell that hosts a role's bottom navigation branches.
///
/// One shell serves all three roles, so the navigation bar behaves and looks
/// identical everywhere. Each branch keeps its own navigation history, so
/// returning to a tab restores where the user left it.
class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        items: items,
        currentIndex: navigationShell.currentIndex,
        onSelect: (int index) => navigationShell.goBranch(
          index,
          // Tapping the tab the user is already on returns that branch to its
          // first screen, which is the expected behaviour on mobile.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
