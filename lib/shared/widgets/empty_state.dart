import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'secondary_button.dart';

/// Shown when a list or section has nothing to display.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  /// Urdu heading. Defaults to the standard no-data heading.
  final String? title;

  /// Urdu explanation.
  final String? message;
  final IconData icon;

  /// Urdu label of the optional action.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Reduces the padding so the state fits inside a card.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(
          compact ? AppSpacing.lg : AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.greenTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 28 : 36,
                color: AppColors.primaryGreen,
              ),
            ),
            AppSpacing.gapLg,
            Text(
              title ?? AppStrings.noData,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.darkGreen,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              message ?? AppStrings.noDataDetail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              AppSpacing.gapLg,
              SecondaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
