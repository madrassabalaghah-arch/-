import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'primary_button.dart';

/// Shown when something fails.
///
/// The heading and the retry label are the standard Urdu wordings, so an error
/// reads the same everywhere in the application.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  /// Urdu heading. Defaults to the standard error heading.
  final String? title;

  /// Urdu explanation.
  final String? message;
  final VoidCallback? onRetry;

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
                color: AppColors.errorSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: compact ? 28 : 36,
                color: AppColors.error,
              ),
            ),
            AppSpacing.gapLg,
            Text(
              title ?? AppStrings.somethingWentWrong,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.error,
              ),
            ),
            AppSpacing.gapXs,
            Text(
              message ?? AppStrings.errorDetail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (onRetry != null) ...<Widget>[
              AppSpacing.gapLg,
              PrimaryButton(
                label: AppStrings.tryAgain,
                icon: Icons.refresh,
                onPressed: onRetry,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
