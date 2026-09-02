import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Visual variant of a primary button.
enum PrimaryButtonVariant {
  /// The default brand action.
  green,

  /// Reserved for recognition, achievements and milestones only.
  gold,
}

/// The main call to action.
///
/// Uses the centralised theme, keeps a comfortable touch target for Urdu
/// labels, and lays out its optional icon with directional spacing so the icon
/// sits correctly in the right-to-left layout.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.variant = PrimaryButtonVariant.green,
  });

  /// Gold variant, reserved for recognition and achievement actions.
  const PrimaryButton.gold({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  }) : variant = PrimaryButtonVariant.gold;

  /// Urdu label of the action.
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final PrimaryButtonVariant variant;

  bool get _isGold => variant == PrimaryButtonVariant.gold;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background =
        _isGold ? AppColors.gold : AppColors.primaryGreen;
    final Color foreground = _isGold ? AppColors.darkGreen : AppColors.white;

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: foreground),
                AppSpacing.hGapSm,
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          );

    final Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor:
            isLoading ? background : AppColors.lightGray,
        disabledForegroundColor:
            isLoading ? foreground : AppColors.disabled,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
