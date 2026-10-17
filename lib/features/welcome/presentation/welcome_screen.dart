import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/widgets.dart';

/// The first screen of the application.
///
/// Cream background, a green and gold brand mark, the temporary product name
/// read from [AppConfig], a short Urdu description and a single call to action.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BrandMark(size: 132),
                  AppSpacing.gapXxl,
                  Text(
                    AppConfig.appNameUrdu,
                    textAlign: TextAlign.center,
                    style: AppTextTheme.brandTitle(AppColors.darkGreen)
                        .copyWith(
                      fontSize: context.isSmallPhone ? 26 : 30,
                    ),
                  ),
                  AppSpacing.gapXs,
                  Text(
                    AppConfig.appTaglineUrdu,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.earthBrown,
                    ),
                  ),
                  AppSpacing.gapLg,
                  const _GoldDivider(),
                  AppSpacing.gapLg,
                  Text(
                    AppStrings.welcome,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    AppConfig.appDescriptionUrdu,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSpacing.gapXxxl,
                  PrimaryButton(
                    label: AppStrings.continueAction,
                    // Flutter mirrors this icon automatically in the right-to-left
                    // layout, so it points the way the reader moves forward.
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push(AppRoutes.signIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short gold rule used to separate the brand mark from the message.
class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 4,
        width: 64,
        decoration: const BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: AppRadius.radiusPill,
        ),
      ),
    );
  }
}
