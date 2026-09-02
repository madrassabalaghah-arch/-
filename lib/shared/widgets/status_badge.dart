import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../models/app_status.dart';

/// A small pill showing the Urdu status label.
///
/// Colours come from [AppStatus] itself, so one status can never look different
/// on two screens.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final AppStatus status;

  /// Hides the icon and tightens the padding, for dense list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: AppRadius.radiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!compact) ...<Widget>[
            Icon(status.icon, size: 14, color: status.foreground),
            AppSpacing.hGapXs,
          ],
          // Flexible so a long Urdu status shortens on a narrow phone
          // instead of overflowing its row.
          Flexible(
            child: Text(
              status.urduLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: status.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
