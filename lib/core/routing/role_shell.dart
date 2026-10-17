import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The frame every signed-in screen sits in: the branch content, an offline
/// strip when the connection is down, and the bottom navigation.
class RoleShell extends ConsumerWidget {
  const RoleShell({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSession?> session = ref.watch(appSessionProvider);

    // Stale values mean the last refresh could not reach the server; an
    // outright error while still authenticated means the same thing. Either
    // way the account stays signed in and the strip says why the figures are
    // not moving, instead of silently showing old numbers as if they were new.
    final bool offline = (session.value?.isStale ?? false) || session.hasError;

    return Scaffold(
      body: Column(
        children: <Widget>[
          if (offline) const _OfflineStrip(),
          Expanded(child: navigationShell),
        ],
      ),
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

/// A thin strip reporting that the device is offline. It never signs anyone
/// out — the session stays exactly as it was until the connection returns.
class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: AppColors.goldTint,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: AppColors.earthBrown,
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  AppStrings.offlineNotice,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.earthBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
