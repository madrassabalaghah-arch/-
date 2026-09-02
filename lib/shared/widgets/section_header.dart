import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// The heading that opens every section of a screen.
///
/// The small accent bar sits at the start of the row, so it appears on the
/// right in the Urdu right-to-left layout without any extra work.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.isGold = false,
  });

  /// Urdu heading text.
  final String title;

  /// Optional Urdu supporting line.
  final String? subtitle;

  /// Optional Urdu label of the trailing action, for example view all.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Recognition sections use the gold accent.
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = isGold ? AppColors.gold : AppColors.primaryGreen;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 4,
            height: 22,
            margin: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: AppRadius.radiusPill,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isGold ? AppColors.earthBrown : AppColors.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.xxs,
                    ),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
            ),
        ],
      ),
    );
  }
}
