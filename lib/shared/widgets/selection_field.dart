import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// A tappable field that shows the current selection and opens a chooser.
///
/// Styled to match [AppFormField] exactly, so a form mixing typed fields and
/// chosen ones still reads as one form.
class SelectionField extends StatelessWidget {
  const SelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    this.onTap,
    this.icon,
    this.isRequired = false,
    this.enabled = true,
  });

  /// Urdu label above the field.
  final String label;

  /// The current selection, or null when nothing is chosen.
  final String? value;

  /// Urdu text shown when nothing is chosen.
  final String placeholder;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isRequired;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.sm,
            start: AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:
                        enabled ? AppColors.textSecondary : AppColors.disabled,
                  ),
                ),
              ),
              if (isRequired)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: AppSpacing.xxs),
                  child: Text('*',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: AppColors.error)),
                ),
            ],
          ),
        ),
        Material(
          color: enabled ? AppColors.white : AppColors.surfaceSoft,
          borderRadius: AppRadius.radiusMd,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppRadius.radiusMd,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon,
                        size: 20,
                        color: enabled ? AppColors.gray : AppColors.disabled),
                    AppSpacing.hGapMd,
                  ],
                  Expanded(
                    child: Text(
                      hasValue ? value! : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: !enabled
                            ? AppColors.disabled
                            : hasValue
                                ? AppColors.textPrimary
                                : AppColors.textLight,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: enabled ? AppColors.gray : AppColors.disabled,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
