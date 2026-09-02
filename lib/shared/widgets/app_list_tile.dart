import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../models/app_status.dart';
import 'dashboard_card.dart';
import 'status_badge.dart';

/// The standard list row.
///
/// Used for graduates, reports, evidence, courses and every other list, so all
/// lists in the application share one rhythm. The leading block sits at the
/// start of the row, which is the right edge in the Urdu layout.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.detail,
    this.icon,
    this.avatarText,
    this.status,
    this.trailing,
    this.onTap,
    this.accentColor,
    this.progress,
  });

  /// Urdu title of the row.
  final String title;

  /// Urdu supporting line.
  final String? subtitle;

  /// Optional third Urdu line, for example the latest activity.
  final String? detail;

  /// Icon shown in the leading block. Ignored when [avatarText] is supplied.
  final IconData? icon;

  /// Initial letter shown instead of an icon, used for people.
  final String? avatarText;

  /// Optional status badge shown at the end of the row.
  final AppStatus? status;

  /// Custom trailing widget. Replaces the default chevron.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Overrides the leading block tint.
  final Color? accentColor;

  /// Optional completion ratio rendered as a thin bar under the text.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColor ?? AppColors.primaryGreen;

    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusMd,
            ),
            child: avatarText != null
                ? Text(
                    avatarText!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Icon(icon ?? Icons.article_outlined, size: 21, color: accent),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (subtitle != null) ...<Widget>[
                  AppSpacing.gapXxs,
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (detail != null) ...<Widget>[
                  AppSpacing.gapXxs,
                  Text(
                    detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
                if (progress != null) ...<Widget>[
                  AppSpacing.gapSm,
                  ClipRRect(
                    borderRadius: AppRadius.radiusPill,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.lightGray,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
                if (status != null) ...<Widget>[
                  AppSpacing.gapSm,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StatusBadge(status: status!, compact: true),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            AppSpacing.hGapSm,
            trailing!,
          ] else if (onTap != null) ...<Widget>[
            AppSpacing.hGapXs,
            const Icon(
              // Mirrored automatically in the right-to-left layout, so it
              // points the way the reader moves forward.
              Icons.chevron_right,
              size: 22,
              color: AppColors.textLight,
            ),
          ],
        ],
      ),
    );
  }
}
