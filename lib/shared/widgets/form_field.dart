import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The labelled text input used by every form.
///
/// Named [AppFormField] rather than FormField so it does not collide with the
/// Flutter class of that name. The Urdu label sits above the field and is
/// aligned to the start, which resolves to the right in the Urdu layout.
class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.isRequired = false,
    this.enabled = true,
    this.prefixIcon,
    this.initialValue,
    this.onChanged,
    this.obscureText = false,
  });

  /// Urdu label shown above the field.
  final String label;

  /// Urdu placeholder shown inside the field.
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  /// Adds the required marker beside the label.
  final bool isRequired;
  final bool enabled;
  final IconData? prefixIcon;
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  /// Hides the entered text, for password fields.
  final bool obscureText;

  /// The standard required-field validator, in Urdu.
  static String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validationRequired;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.disabled,
                  ),
                ),
              ),
              if (isRequired)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.xxs),
                  child: Text(
                    '*',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.disabled,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            fillColor: enabled ? AppColors.white : AppColors.surfaceSoft,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: AppColors.gray),
          ),
        ),
      ],
    );
  }
}
