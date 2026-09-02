import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// The supporting action beside a [PrimaryButton].
///
/// White or transparent surface with a green outline and green label, exactly
/// as defined by the official button system.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.transparent = false,
  });

  /// Urdu label of the action.
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  /// When true the button sits on an existing surface without its own fill.
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        backgroundColor: transparent ? Colors.transparent : AppColors.white,
        disabledForegroundColor: AppColors.disabled,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        side: BorderSide(
          color: onPressed == null
              ? AppColors.lightGray
              : AppColors.primaryGreen,
          width: 1.4,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20, color: AppColors.primaryGreen),
            AppSpacing.hGapSm,
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
