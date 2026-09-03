import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/data_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

/// Real Supabase registration.
///
/// The role is never sent from here. A database trigger creates the profile
/// and grants the default فاضلہ / فاضل role, so an account cannot register
/// itself as a mentor or administrator.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  final TextEditingController _regNumber = TextEditingController();

  bool _busy = false;
  String? _error;

  /// Until a registration number verifies, the account fields stay hidden.
  /// Registration is closed to anyone who did not complete the workshop.
  WorkshopVerification? _verified;

  String _verdictMessage(WorkshopVerdict v) {
    switch (v) {
      case WorkshopVerdict.notFound:
        return AppStrings.regNotFound;
      case WorkshopVerdict.notCompleted:
        return AppStrings.regNotCompleted;
      case WorkshopVerdict.notEligible:
        return AppStrings.regNotEligible;
      case WorkshopVerdict.alreadyUsed:
        return AppStrings.regAlreadyUsed;
      case WorkshopVerdict.ok:
      case WorkshopVerdict.unknown:
        return AppStrings.somethingWentWrong;
    }
  }

  Future<void> _verify() async {
    final String number = _regNumber.text.trim();
    if (number.isEmpty) {
      setState(() => _error = AppStrings.regRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final WorkshopVerification result = await ref
          .read(workshopRepositoryProvider)
          .verify(number);
      setState(() {
        _verified = result.valid ? result : null;
        _error = result.valid ? null : _verdictMessage(result.verdict);
      });
    } catch (error) {
      setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _regNumber.dispose();
    _name.dispose();
    _email.dispose();
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
      await ref
          .read(appSessionProvider.notifier)
          .signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            registrationNumber: _regNumber.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.signUpSuccess)));
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
      title: AppStrings.signUpTitle,
      subtitle: AppStrings.signUpSubtitle,
      backTo: AppRoutes.signIn,
      // Wrap rather than Row: the Urdu prompt plus the action can exceed
      // one line on a narrow phone, and a Row would overflow.
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            AppStrings.alreadyHaveAccount,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.signIn),
            child: const Text(AppStrings.signIn),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Step one. Registration is closed to the public, so nothing else
            // is offered until a workshop number verifies.
            AppFormField(
              label: AppStrings.registrationNumber,
              hintText: AppStrings.hintRegistrationNumber,
              controller: _regNumber,
              isRequired: true,
              enabled: !_busy && _verified == null,
              prefixIcon: Icons.confirmation_number_outlined,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                  ? AppStrings.regRequired
                  : null,
            ),
            AppSpacing.gapMd,
            if (_verified == null) ...<Widget>[
              PrimaryButton(
                label: AppStrings.verifyNumber,
                icon: Icons.verified_outlined,
                isLoading: _busy,
                onPressed: _verify,
              ),
              if (_error != null) ...<Widget>[
                AppSpacing.gapLg,
                AuthErrorBanner(message: _error!),
              ],
              AppSpacing.gapLg,
              Text(
                AppStrings.publicSignupClosed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ] else ...<Widget>[
              _VerifiedBanner(
                name: _verified!.participantName,
                onChange: _busy
                    ? null
                    : () => setState(() {
                        _verified = null;
                        _error = null;
                      }),
              ),
              AppSpacing.gapXl,
              AppFormField(
                label: AppStrings.labelName,
                hintText: AppStrings.hintName,
                controller: _name,
                isRequired: true,
                enabled: !_busy,
                prefixIcon: Icons.person_outline,
                validator: AppFormField.requiredValidator,
              ),
              AppSpacing.gapLg,
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
                  return value.contains('@')
                      ? null
                      : AppStrings.validationEmail;
                },
              ),
              AppSpacing.gapLg,
              AppFormField(
                label: AppStrings.labelPassword,
                hintText: AppStrings.hintPassword,
                controller: _password,
                isRequired: true,
                enabled: !_busy,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.validationRequired;
                  }
                  return value.length < 8
                      ? AppStrings.validationPassword
                      : null;
                },
              ),
              AppSpacing.gapLg,
              AppFormField(
                label: AppStrings.labelConfirmPassword,
                controller: _confirm,
                isRequired: true,
                enabled: !_busy,
                obscureText: true,
                prefixIcon: Icons.lock_reset_outlined,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.validationRequired;
                  }
                  return value == _password.text
                      ? null
                      : AppStrings.validationPasswordMatch;
                },
              ),
              if (_error != null) ...<Widget>[
                AppSpacing.gapLg,
                AuthErrorBanner(message: _error!),
              ],
              AppSpacing.gapXl,
              PrimaryButton(
                label: AppStrings.signUp,
                icon: Icons.person_add_alt_outlined,
                isLoading: _busy,
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirms which workshop record the applicant verified against, so they can
/// spot a mistyped number before creating an account under someone else's
/// name.
class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner({required this.name, required this.onChange});

  final String? name;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.verified_rounded,
            size: 20,
            color: AppColors.primaryGreen,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.verifiedAs,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                ),
                if (name != null)
                  Text(
                    name!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.darkGreen,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(AppStrings.changeNumber),
          ),
        ],
      ),
    );
  }
}
