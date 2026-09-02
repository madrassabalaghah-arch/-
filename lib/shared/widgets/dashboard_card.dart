import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// The four card treatments allowed by the design system.
enum DashboardCardVariant {
  /// White surface, soft border, subtle shadow. The default everywhere.
  standard,

  /// Green gradient. High emphasis only.
  gradient,

  /// Gold gradient. Recognition and achievements only.
  gold,

  /// White surface with a small coloured accent stripe at the start edge.
  info,
}

/// The one card used across the whole application.
///
/// Every screen composes its content inside this card so padding, radius,
/// border and shadow never drift between screens.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.variant = DashboardCardVariant.standard,
    this.onTap,
    this.padding,
    this.accentColor,
  });

  final Widget child;
  final DashboardCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Accent stripe colour for [DashboardCardVariant.info].
  final Color? accentColor;

  /// Width of the accent stripe on an information card.
  static const double _accentWidth = 4;

  bool get _hasGradient =>
      variant == DashboardCardVariant.gradient ||
      variant == DashboardCardVariant.gold;

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? AppColors.primaryGreen;

    // A BoxDecoration may not combine a rounded corner with a non-uniform
    // border, so the information variant keeps a uniform border and draws its
    // accent as a clipped stripe instead.
    final BoxDecoration decoration = switch (variant) {
      DashboardCardVariant.gradient => BoxDecoration(
          gradient: AppGradients.green,
          borderRadius: AppRadius.radiusLg,
          boxShadow: AppShadows.tinted(AppColors.primaryGreen),
        ),
      DashboardCardVariant.gold => BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: AppRadius.radiusLg,
          boxShadow: AppShadows.tinted(AppColors.gold),
        ),
      DashboardCardVariant.standard ||
      DashboardCardVariant.info =>
        const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.radiusLg,
          border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
          boxShadow: AppShadows.card,
        ),
    };

    Widget content = Padding(
      padding: padding ??
          (variant == DashboardCardVariant.info
              // Leave room for the stripe so the text never sits on top of it.
              ? const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.cardPadding + _accentWidth,
                  AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
                )
              : AppSpacing.cardInsets),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusLg,
        splashColor: _hasGradient
            ? AppColors.white.withValues(alpha: 0.12)
            : AppColors.greenTint,
        child: content,
      );
    }

    if (variant == DashboardCardVariant.info) {
      content = Stack(
        children: <Widget>[
          content,
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: _accentWidth,
            child: ColoredBox(color: accent),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusLg,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
