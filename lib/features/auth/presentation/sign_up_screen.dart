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

/// Registration for someone who completed the three-month course.
///
/// One form, verified in one step. The رقم التسجیل and the name are checked
/// against the imported register; the category, وفاق and institution are the
/// participant's own answers and are stored on their profile. There is no
/// approval queue — a valid, unused number with a matching name creates the
/// account, and anything else is refused with the reason why.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _name = TextEditingController();

  /// ولدیت, kept apart from the name. The register's own column has held
  /// the two together, and requiring them typed as one string is what refused
  /// people who entered their father's name as the form asked them to.
  final TextEditingController _father = TextEditingController();
  final TextEditingController _period = TextEditingController();

  /// The matched record. Until it exists only the three identifying fields are
  /// shown; the rest of registration continues once the register confirms them.
  CourseVerification? _verified;
  final TextEditingController _institute = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  /// 'male' is فاضل and is offered first, per the display order the brief sets.
  String _gender = 'male';
  String? _wifaqId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _father.dispose();
    _period.dispose();
    _institute.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Turns a refusal from the register into the sentence the brief specifies.
  String _messageFor(CourseVerdict verdict) {
    switch (verdict) {
      case CourseVerdict.missingNumber:
        return AppStrings.regRequired;
      case CourseVerdict.notFound:
        return AppStrings.regNotFound;
      case CourseVerdict.nameMismatch:
        return AppStrings.regNameMismatch;
      case CourseVerdict.periodMismatch:
        return AppStrings.regPeriodMismatch;
      case CourseVerdict.notEligible:
        return AppStrings.regNotEligible;
      case CourseVerdict.alreadyUsed:
        return AppStrings.regAlreadyUsed;
      case CourseVerdict.ok:
      case CourseVerdict.unknown:
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
      final CourseVerification result = await ref
          .read(courseRepositoryProvider)
          .verify(
            _number.text,
            fullName: _name.text,
            fatherName: _father.text,
            coursePeriod: _period.text,
          );
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
    if (_wifaqId == null) {
      setState(() => _error = AppStrings.noWifaqSelected);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(appSessionProvider.notifier).signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            fatherName: _father.text,
            registrationNumber: _number.text,
            gender: _gender,
            wifaqId: _wifaqId,
            instituteName: _institute.text,
            coursePeriod: _period.text,
          );

      if (!mounted) {
        return;
      }
      // The router sends a signed-in account to its own dashboard, so there is
      // nothing to navigate to here.
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.verifiedActivated)),
        );
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
    final AsyncValue<List<WifaqItem>> wifaqs = ref.watch(wifaqListProvider);

    return AuthScaffold(
      title: AppStrings.signUpTitle,
      subtitle: AppStrings.courseGateSubtitle,
      backTo: AppRoutes.signIn,
      // Wrap rather than Row: the Urdu sentence plus the action does not fit
      // on one line on a narrow phone, and a Row would overflow.
      footer: Column(
        children: <Widget>[
          Wrap(
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
          // Someone refused here because they are not a course participant
          // may be a mentor or administrator with an invitation instead.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const Text(AppStrings.staffSignUpPrompt),
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
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_error != null) ...<Widget>[
              AuthErrorBanner(message: _error!),
              AppSpacing.gapLg,
            ],
            const _Notice(message: AppStrings.publicSignupClosed),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.registrationNumber,
              hintText: AppStrings.hintRegistrationNumber,
              controller: _number,
              isRequired: true,
              enabled: !_busy && _verified == null,
              prefixIcon: Icons.badge_outlined,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.regRequired
                      : null,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.participantName,
              controller: _name,
              isRequired: true,
              enabled: !_busy && _verified == null,
              prefixIcon: Icons.person_outline,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapLg,
            // Optional: the register may hold no ولدیت at all, and someone
            // whose row holds only their own name must still get through.
            AppFormField(
              label: AppStrings.participantFatherName,
              hintText: AppStrings.hintFatherNameOptional,
              controller: _father,
              enabled: !_busy && _verified == null,
              prefixIcon: Icons.person_outline,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.coursePeriod,
              hintText: AppStrings.hintCoursePeriod,
              controller: _period,
              isRequired: true,
              enabled: !_busy && _verified == null,
              prefixIcon: Icons.date_range_outlined,
              validator: AppFormField.requiredValidator,
            ),
            if (_verified == null) ...<Widget>[
              AppSpacing.gapXl,
              PrimaryButton(
                label: _busy ? AppStrings.verifying : AppStrings.verifyNumber,
                icon: Icons.verified_outlined,
                isLoading: _busy,
                onPressed: _busy ? null : _verify,
              ),
            ] else ...<Widget>[
              AppSpacing.gapLg,
              _MatchedRecord(
                verification: _verified!,
                onChange: _busy ? null : () => setState(() => _verified = null),
              ),
            AppSpacing.gapLg,
            _CategoryField(
              value: _gender,
              enabled: !_busy,
              onChanged: (String value) => setState(() => _gender = value),
            ),
            AppSpacing.gapLg,
            wifaqs.when(
              loading: () => const LoadingState(compact: true),
              error: (Object e, StackTrace s) =>
                  const _Notice(message: AppStrings.noWifaqsYet),
              data: (List<WifaqItem> items) => DropdownButtonFormField<String>(
                initialValue: _wifaqId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.selectWifaq,
                  prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                ),
                items: <DropdownMenuItem<String>>[
                  for (final WifaqItem w in items)
                    DropdownMenuItem<String>(
                      value: w.id,
                      child: Text(w.name),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (String? value) => setState(() => _wifaqId = value),
              ),
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.newInstituteName,
              controller: _institute,
              isRequired: true,
              enabled: !_busy,
              prefixIcon: Icons.location_city_outlined,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.labelEmail,
              controller: _email,
              isRequired: true,
              enabled: !_busy,
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
                return value.length < 8 ? AppStrings.validationPassword : null;
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

/// A quiet explanatory line, for facts that are not errors.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.earthBrown),
      ),
    );
  }
}

/// فاضل or فاضلہ, in that order, chosen in the app rather than imported.
class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.sm,
            start: AppSpacing.xs,
          ),
          child: Text(
            AppStrings.selectCategory,
            style: theme.textTheme.labelLarge,
          ),
        ),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'male',
              label: Text(AppStrings.maleLabel),
            ),
            ButtonSegment<String>(
              value: 'female',
              label: Text(AppStrings.femaleLabel),
            ),
          ],
          selected: <String>{value},
          onSelectionChanged: enabled
              ? (Set<String> selection) => onChanged(selection.first)
              : null,
        ),
      ],
    );
  }
}

/// Confirms which register entry was matched, including its دورانیہ, before
/// the applicant fills in anything else — and lets them go back if it is not
/// theirs.
class _MatchedRecord extends StatelessWidget {
  const _MatchedRecord({required this.verification, required this.onChange});

  final CourseVerification verification;
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
                Text(AppStrings.recordMatched, style: theme.textTheme.titleSmall),
                if (verification.participantName != null)
                  Text(verification.participantName!,
                      style: theme.textTheme.bodyMedium),
                if (verification.participantPeriod != null)
                  Text(
                    '${AppStrings.coursePeriod}: ${verification.participantPeriod}',
                    style: theme.textTheme.labelSmall,
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
