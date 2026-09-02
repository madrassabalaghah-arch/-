import 'package:flutter/material.dart';

import '../../features/auth/presentation/sign_out_action.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';

/// The page shell used by every screen.
///
/// It supplies the cream background, the branded app bar and a content column
/// that is centred and width limited on tablets instead of being stretched.
/// Using one shell everywhere is what keeps the three dashboards inside a
/// single visual identity.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.useGradientAppBar = false,
    this.gradient,
    this.showAppBar = true,
    this.padBody = true,
    this.backgroundColor,
    this.showSignOut,
  });

  /// Urdu title shown in the app bar.
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  /// Dashboard app bars may use the official green gradient.
  final bool useGradientAppBar;

  /// Overrides the app bar gradient, used by the administrator surfaces.
  final LinearGradient? gradient;
  final bool showAppBar;

  /// When false the body handles its own padding, for screens whose header
  /// must run edge to edge.
  final bool padBody;
  final Color? backgroundColor;

  /// Whether to offer sign out in the app bar.
  ///
  /// Left null it decides for itself: a screen the user cannot back out of is
  /// a landing screen, so it needs a way out and gets sign out. A screen that
  /// was pushed already has a back button, so it does not. That keeps an exit
  /// on every root of every role without annotating each screen.
  final bool? showSignOut;

  @override
  Widget build(BuildContext context) {
    final bool canPop = ModalRoute.of(context)?.canPop ?? false;
    final bool offerSignOut = showSignOut ?? !canPop;

    final List<Widget> barActions = <Widget>[
      ...?actions,
      if (offerSignOut) const SignOutAction(),
    ];

    final Widget content = padBody
        ? Padding(padding: AppSpacing.screenPadding, child: body)
        : body;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: showAppBar
          ? AppBar(
              title: title == null ? null : Text(title!),
              actions: barActions,
              flexibleSpace: useGradientAppBar
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: gradient ?? AppGradients.green,
                      ),
                    )
                  : null,
            )
          : null,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        // The top inset is handled either by the app bar or, on screens
        // without one, by the gradient header inside the body.
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
