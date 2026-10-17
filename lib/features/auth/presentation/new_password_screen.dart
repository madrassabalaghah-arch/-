import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

/// Where a پاس ورڈ بھول گئے؟ link ends.
///
/// Opening the emailed link signs the account in for this one purpose, so by
/// the time this screen is reached there is a session and the only thing left
/// to do is store a new password. Without this screen the link would leave the
/// reader signed in with the password they could not remember.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.passwordChanged)),
        );
      // The account is already signed in, so the router's own redirect takes
      // it on to the right dashboard from here.
      context.go(AppRoutes.welcome);
    } catch (error) {
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.newPasswordTitle,
      subtitle: AppStrings.newPasswordSubtitle,
      backTo: AppRoutes.signIn,
      footer: const SizedBox.shrink(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppFormField(
              label: AppStrings.labelPassword,
              hintText: AppStrings.hintPassword,
              controller: _password,
              isRequired: true,
              enabled: !_busy,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (String? value) => (value == null || value.length < 8)
                  ? AppStrings.validationPassword
                  : null,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.labelConfirmPassword,
              controller: _confirm,
              isRequired: true,
              enabled: !_busy,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (String? value) => value == _password.text
                  ? null
                  : AppStrings.validationPasswordMatch,
            ),
            if (_error != null) ...<Widget>[
              AppSpacing.gapSm,
              AuthErrorBanner(message: _error!),
            ],
            AppSpacing.gapLg,
            PrimaryButton(
              label: AppStrings.savePassword,
              icon: Icons.check_rounded,
              isLoading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
