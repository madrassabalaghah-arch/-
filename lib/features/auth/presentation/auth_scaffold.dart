import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';

import '../../../core/routing/app_routes.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/utils/responsive.dart';

/// Shared frame for the sign in and sign up screens.
///
/// Keeps the brand mark, cream ground and card treatment identical to the
/// welcome screen, so authentication feels like part of the same product
/// rather than a bolted-on gate.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    this.backTo,
  });

  /// Urdu heading of the form.
  final String title;

  /// Urdu supporting line.
  final String subtitle;

  /// The form itself.
  final Widget child;

  /// Row offering the opposite action.
  final Widget footer;

  /// Where the back control goes when there is nothing on the stack to pop,
  /// which happens on a cold start straight into this route.
  final String? backTo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      // A flat bar carrying only the back control, so the screen keeps its
      // calm cream ground rather than gaining a green header.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        // BackButton rather than a hand-rolled IconButton: it carries the
        // platform icon, mirrors itself in the right-to-left layout, and picks
        // up the Urdu tooltip from the Material localisations.
        leading: BackButton(
          color: AppColors.darkGreen,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(backTo ?? AppRoutes.welcome);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      height: 84,
                      width: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2.4),
                        boxShadow: AppShadows.tinted(AppColors.primaryGreen),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 38,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,
                  Text(
                    AppConfig.appNameUrdu,
                    textAlign: TextAlign.center,
                    style: AppTextTheme.brandTitle(AppColors.darkGreen).copyWith(
                      fontSize: context.isSmallPhone ? 21 : 24,
                    ),
                  ),
                  AppSpacing.gapXxs,
                  Text(
                    AppConfig.appTaglineUrdu,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.earthBrown,
                    ),
                  ),
                  AppSpacing.gapXxl,
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.radiusLg,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.border),
                      ),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.darkGreen,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Text(subtitle, style: theme.textTheme.bodySmall),
                        AppSpacing.gapXl,
                        child,
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error banner shared by both authentication screens.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  /// Urdu explanation of what went wrong.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns an authentication failure into an accurate Urdu message.
///
/// Reporting every failure as "wrong email or password" is actively harmful:
/// it sends the user off to reset a password that was never the problem. A
/// release build with no network, an unconfirmed address and a genuinely wrong
/// password all need different responses, so they get different messages.
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final String code = (error.code ?? '').toLowerCase();
    final String message = error.message.toLowerCase();

    if (code.contains('email_not_confirmed') ||
        message.contains('not confirmed')) {
      return AppStrings.emailNotConfirmed;
    }
    if (code.contains('over_request_rate_limit') ||
        message.contains('rate limit') ||
        error.statusCode == '429') {
      return AppStrings.tooManyAttempts;
    }
    if (code.contains('invalid_credentials') ||
        message.contains('invalid login')) {
      return AppStrings.authFailed;
    }
    // Anything else is shown as reported rather than guessed at.
    return error.message.isEmpty ? AppStrings.somethingWentWrong : error.message;
  }

  // A dropped connection, a blocked socket, or a release build without the
  // INTERNET permission all land here rather than in AuthException.
  final String text = error.toString().toLowerCase();
  if (text.contains('socket') ||
      text.contains('failed host lookup') ||
      text.contains('connection') ||
      text.contains('network')) {
    return AppStrings.networkError;
  }
  return AppStrings.somethingWentWrong;
}
