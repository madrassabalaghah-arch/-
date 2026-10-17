import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

/// Real Supabase email and password sign in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _busy = false;
  String? _error;

  /// True when the last sign in failed because the address is not confirmed.
  /// Only then is resending offered, because Supabase refuses to resend for
  /// an address that is already confirmed.
  bool _needsConfirmation = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _needsConfirmation = false;
    });

    try {
      await ref.read(appSessionProvider.notifier).signIn(
            email: _email.text,
            password: _password.text,
          );
      // The router redirect sends the user to their own dashboard once the
      // session and role have loaded, so nothing to navigate to here.
    } catch (error) {
      final String message = authErrorMessage(error);
      setState(() {
        _error = message;
        _needsConfirmation = message == AppStrings.emailNotConfirmed;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Sends the confirmation message again, for an address that was never
  /// confirmed — for example because the first message was lost, or the link
  /// in it had already expired.
  Future<void> _resendConfirmation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resendConfirmation(_email.text.trim());
      if (!mounted) {
        return;
      }
      setState(() => _needsConfirmation = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.confirmationResent)),
        );
    } catch (error) {
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final String email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = AppStrings.validationEmail);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.resetLinkSent)));
    } catch (error) {
      setState(() => _error = authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.signInTitle,
      subtitle: AppStrings.signInSubtitle,
      backTo: AppRoutes.welcome,
      // Wrap rather than Row: the Urdu prompt plus the action can exceed
      // one line on a narrow phone, and a Row would overflow.
      footer: Column(
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                AppStrings.noAccountYet,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: _busy ? null : () => context.push(AppRoutes.signUp),
                child: const Text(AppStrings.signUp),
              ),
            ],
          ),
          // Mentors and administrators who are not on the course register
          // join with the code an administrator sent them.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                AppStrings.staffSignUpPrompt,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed:
                    _busy ? null : () => context.push(AppRoutes.staffSignUp),
                child: const Text(AppStrings.staffSignUpLink),
              ),
            ],
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppFormField(
              label: AppStrings.labelEmail,
              hintText: AppStrings.hintEmail,
              controller: _email,
              isRequired: true,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_outlined,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.validationRequired;
                }
                return value.contains('@') ? null : AppStrings.validationEmail;
              },
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.labelPassword,
              controller: _password,
              isRequired: true,
              enabled: !_busy,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.validationRequired;
                }
                return null;
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _busy ? null : _resetPassword,
                child: const Text(AppStrings.forgotPassword),
              ),
            ),
            if (_error != null) ...<Widget>[
              AppSpacing.gapSm,
              AuthErrorBanner(message: _error!),
              if (_needsConfirmation)
                Align(
                  alignment: AlignmentDirectional.center,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _resendConfirmation,
                    icon: const Icon(Icons.mark_email_unread_outlined,
                        size: 18),
                    label: const Text(AppStrings.resendConfirmation),
                  ),
                ),
            ],
            AppSpacing.gapLg,
            PrimaryButton(
              label: AppStrings.signIn,
              icon: Icons.login_rounded,
              isLoading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
