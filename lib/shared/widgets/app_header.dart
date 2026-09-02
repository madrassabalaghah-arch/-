import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/urdu_numbers.dart';

/// The gradient greeting header that opens every dashboard.
///
/// It carries the Urdu greeting, the signed-in user's name, the profile
/// avatar and the notification bell. Everything is laid out with directional
/// widgets, so the avatar sits on the right and the bell on the left in the
/// Urdu layout.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.name,
    required this.roleTitle,
    this.subtitle,
    this.avatarText,
    this.notificationCount = 0,
    this.onProfileTap,
    this.onNotificationsTap,
    this.gradient,
    this.actions = const <Widget>[],
  });

  /// Urdu name of the signed-in demonstration user.
  final String name;

  /// Urdu role title shown beneath the name.
  final String roleTitle;

  /// Optional Urdu third line, for example the institute name.
  final String? subtitle;

  /// Letter shown inside the avatar circle.
  final String? avatarText;

  /// Number of unread notifications shown on the bell badge.
  final int notificationCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;

  /// Overrides the header gradient. Administrators use the darker variant.
  final LinearGradient? gradient;

  /// Extra controls shown after the notification bell, such as sign out.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String initial =
        avatarText ?? (name.isEmpty ? '' : name.substring(0, 1));

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.green,
        borderRadius: AppRadius.headerBottom,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            _Avatar(initial: initial, onTap: onProfileTap),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppStrings.salaam,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  AppSpacing.gapXxs,
                  Text(
                    subtitle == null ? roleTitle : '$roleTitle • $subtitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hGapSm,
            _NotificationBell(
              count: notificationCount,
              onTap: onNotificationsTap,
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, this.onTap});

  final String initial;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusPill,
      child: Container(
        height: 52,
        width: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 1.6),
        ),
        child: Text(
          initial,
          style: theme.textTheme.titleLarge?.copyWith(color: AppColors.white),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Tooltip(
      message: AppStrings.notifications,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusPill,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.white,
                size: 26,
              ),
              if (count > 0)
                PositionedDirectional(
                  top: -4,
                  end: -4,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: Text(
                      UrduNumbers.fromInt(count),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
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
