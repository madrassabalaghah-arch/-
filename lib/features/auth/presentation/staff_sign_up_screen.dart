import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

/// Registration for a مربی or منتظم an administrator has invited.
///
/// Two steps, like the course registration. The email and the invitation
/// code are checked first, and only a match moves on to choosing a password.
/// The role is never chosen here: the signup trigger re-checks the email and
/// code and takes the role and the name from the invitation itself.
class StaffSignUpScreen extends ConsumerStatefulWidget {
  const StaffSignUpScreen({super.key});

  @override
  ConsumerState<StaffSignUpScreen> createState() => _StaffSignUpScreenState();
}

class _StaffSignUpScreenState extends ConsumerState<StaffSignUpScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  /// The matched invitation. Until it exists only the email and the code are
  /// asked for.
  StaffInviteCheck? _verified;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _messageFor(StaffInviteVerdict verdict) {
    switch (verdict) {
      case StaffInviteVerdict.missing:
        return AppStrings.inviteRequired;
      case StaffInviteVerdict.notFound:
        return AppStrings.inviteNotFound;
      case StaffInviteVerdict.alreadyUsed:
        return AppStrings.inviteUsed;
      case StaffInviteVerdict.emailRegistered:
        return AppStrings.inviteEmailHasAccount;
      case StaffInviteVerdict.ok:
      case StaffInviteVerdict.unknown:
        return AppStrings.somethingWentWrong;
    }
  }

  Future<void> _verify() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final StaffInviteCheck result = await ref
          .read(authRepositoryProvider)
          .verifyStaffInvite(email: _email.text, code: _code.text);
      setState(() {
        _busy = false;
        if (result.valid) {
          _verified = result;
        } else {
          _error = _messageFor(result.verdict);
        }
      });
    } catch (error) {
      setState(() {
        _busy = false;
        _error = authErrorMessage(error);
      });
    }
  }

  Future<void> _submit() async {
    if (_verified == null || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final bool signedIn =
          await ref.read(appSessionProvider.notifier).signUpWithInvite(
                email: _email.text,
                password: _password.text,
                inviteCode: _code.text,
              );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(signedIn
              ? AppStrings.staffAccountCreated
              : AppStrings.signUpSuccess),
        ));
      // Signed in: the router sends the account to its own dashboard. Not
      // yet signed in: the address must be confirmed first, then sign in.
      if (!signedIn) {
        context.go(AppRoutes.signIn);
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        // The trigger refused the signup, which the auth service reports
        // only as a database error: the invitation was withdrawn or used in
        // the moment since it was checked.
        if (error.message.toLowerCase().contains('database error')) {
          _verified = null;
          _error = AppStrings.inviteNotFound;
        } else {
          _error = authErrorMessage(error);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = authErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.staffSignUpTitle,
      subtitle: AppStrings.staffSignUpSubtitle,
      backTo: AppRoutes.signIn,
      // Wrap rather than Row, for the same narrow-phone reason as sign up.
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text(AppStrings.alreadyHaveAccount),
          TextButton(
            onPressed: _busy ? null : () => context.go(AppRoutes.signIn),
            child: const Text(AppStrings.signIn),
          ),
        ],
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_error != null) ...<Widget>[
              AuthErrorBanner(message: _error!),
              AppSpacing.gapLg,
            ],
            AppFormField(
              label: AppStrings.labelEmail,
              controller: _email,
              isRequired: true,
              enabled: !_busy && _verified == null,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.validationRequired;
                }
                return value.contains('@') ? null : AppStrings.validationEmail;
              },
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.inviteCode,
              hintText: AppStrings.hintInviteCode,
              controller: _code,
              isRequired: true,
              enabled: !_busy && _verified == null,
              prefixIcon: Icons.vpn_key_outlined,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.validationRequired;
                }
                return StaffInvite.normaliseCode(value).length == 8
                    ? null
                    : AppStrings.inviteCodeLength;
              },
            ),
            if (_verified == null) ...<Widget>[
              AppSpacing.gapXl,
              PrimaryButton(
                label: _busy ? AppStrings.verifying : AppStrings.verifyInvite,
                icon: Icons.verified_outlined,
                isLoading: _busy,
                onPressed: _busy ? null : _verify,
              ),
            ] else ...<Widget>[
              AppSpacing.gapLg,
              _MatchedInvite(
                check: _verified!,
                onChange: _busy ? null : () => setState(() => _verified = null),
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
              AppSpacing.gapXl,
              PrimaryButton(
                label: _busy ? AppStrings.verifying : AppStrings.signUp,
                icon: Icons.how_to_reg_outlined,
                isLoading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirms whose invitation was matched, and as what, before a password is
/// chosen — and lets the person go back if it is not theirs.
class _MatchedInvite extends StatelessWidget {
  const _MatchedInvite({required this.check, required this.onChange});

  final StaffInviteCheck check;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.verified_outlined, color: AppColors.primaryGreen),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppStrings.inviteMatched,
                    style: theme.textTheme.titleSmall),
                if (check.name != null)
                  Text(check.name!, style: theme.textTheme.bodyMedium),
                if (check.role != null)
                  Text('${AppStrings.invitedAs} ${check.role!.urduTitle}',
                      style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text(AppStrings.changeInvite),
          ),
        ],
      ),
    );
  }
}
