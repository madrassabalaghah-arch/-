import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// The search input used on every list screen.
///
/// The search icon is placed with [TextField.prefixIcon], which Flutter already
/// resolves directionally, so the icon sits at the start of the field in the
/// right-to-left layout.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onFilterTap,
  });

  /// Urdu placeholder. Defaults to the standard search wording.
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// When supplied a filter button is shown beside the field.
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget field = TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText ?? AppStrings.hintSearchGeneral,
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.gray,
          size: 20,
        ),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );

    if (onFilterTap == null) {
      return field;
    }

    return Row(
      children: <Widget>[
        Expanded(child: field),
        AppSpacing.hGapSm,
        Tooltip(
          message: AppStrings.filter,
          child: Material(
            color: AppColors.white,
            borderRadius: AppRadius.radiusMd,
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: AppRadius.radiusMd,
              child: Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.tune,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
