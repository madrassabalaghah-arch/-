import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The standard loading indicator with its Urdu caption.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message,
    this.compact = false,
  });

  /// Urdu message. Defaults to the standard loading wording.
  final String? message;

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
            const SizedBox(
              height: 34,
              width: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryGreen,
              ),
            ),
            AppSpacing.gapLg,
            Text(
              message ?? AppStrings.loading,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
