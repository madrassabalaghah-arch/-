import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The labelled text input used by every form.
///
/// Named [AppFormField] rather than FormField so it does not collide with the
/// Flutter class of that name. The Urdu label sits above the field and is
/// aligned to the start, which resolves to the right in the Urdu layout.
class AppFormField extends StatefulWidget {
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

  /// Hides the entered text, for password fields. A field declared this way
  /// starts hidden and gains an eye button to reveal what was typed.
  final bool obscureText;

  /// The standard required-field validator, in Urdu.
  static String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validationRequired;
    }
    return null;
  }

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  /// Whether the text is currently hidden. Seeded from the widget so a
  /// password starts hidden, then toggled by the eye button. Only this flag
  /// changes, so revealing the text never disturbs what was typed.
  late bool _hidden = widget.obscureText;

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
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: widget.enabled
                        ? AppColors.textSecondary
                        : AppColors.disabled,
                  ),
                ),
              ),
              if (widget.isRequired)
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
          controller: widget.controller,
          initialValue:
              widget.controller == null ? widget.initialValue : null,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          obscureText: _hidden,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.disabled,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            fillColor: widget.enabled ? AppColors.white : AppColors.surfaceSoft,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, size: 20, color: AppColors.gray),
            // Only a password field carries the reveal button, so ordinary
            // fields look exactly as they did.
            suffixIcon: !widget.obscureText
                ? null
                : IconButton(
                    tooltip: _hidden
                        ? AppStrings.showPassword
                        : AppStrings.hidePassword,
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.gray,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  ),
          ),
        ),
      ],
    );
  }
}
