import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// One destination in the bottom navigation bar.
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Urdu label of the destination.
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The bottom navigation bar shared by all three roles.
///
/// Material 3 [NavigationBar] already mirrors the destination order for
/// right-to-left layouts, so the first item appears on the right in the Urdu
/// interface without any manual reordering.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: AppShadows.navigation,
        border: BorderDirectional(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: currentIndex.clamp(0, items.length - 1),
          onDestinationSelected: onSelect,
          destinations: <Widget>[
            for (final AppNavItem item in items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
                tooltip: item.label,
              ),
          ],
        ),
      ),
    );
  }
}
