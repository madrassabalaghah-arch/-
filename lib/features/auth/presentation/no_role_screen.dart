import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_providers.dart';

/// Shown when a signed-in account holds no role.
///
/// This is a real state, not an error: the account exists and the session is
/// valid, but an administrator has not yet granted access. Failing closed
/// here is deliberate — the app never guesses a role.
class NoRoleScreen extends ConsumerWidget {
  const NoRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: AppStrings.welcome,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const EmptyState(
            icon: Icons.lock_person_outlined,
            title: AppStrings.noRoleAssigned,
            message: AppStrings.awaitingAccess,
          ),
          AppSpacing.gapLg,
          SecondaryButton(
            label: AppStrings.signOut,
            icon: Icons.logout_rounded,
            expanded: false,
            onPressed: () => ref.read(appSessionProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
