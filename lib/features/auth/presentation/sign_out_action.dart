import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_providers.dart';

/// Sign out control, available to every role.
///
/// Asks for confirmation first: signing out is easy to hit by accident next
/// to the notification bell, and recovering means typing a password again.
class SignOutAction extends ConsumerWidget {
  const SignOutAction({
    super.key,
    this.onGradient = true,
  });

  /// True when placed on a gradient header, where the icon must be white.
  final bool onGradient;

  static Future<void> confirmAndSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.signOut),
            content: const Text(AppStrings.signOutConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  AppStrings.signOut,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }
    // The router redirect sends the user back to sign in as soon as the
    // session clears, so there is nothing to navigate to here.
    await ref.read(appSessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: AppStrings.signOut,
      icon: Icon(
        Icons.logout_rounded,
        color: onGradient ? AppColors.white : AppColors.primaryGreen,
        size: 22,
      ),
      onPressed: () => confirmAndSignOut(context, ref),
    );
  }
}
