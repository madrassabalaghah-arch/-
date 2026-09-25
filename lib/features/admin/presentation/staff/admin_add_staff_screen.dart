import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import 'admin_staff_screen.dart';

/// Invites a مربی or منتظم who is not on the course register.
///
/// The administrator enters the name, the email and the role; the database
/// issues a single-use code, which is shown once the invitation exists so it
/// can be passed on. Nothing here grants a role directly: the role is granted
/// only when that person signs up with that email and that code.
class AdminAddStaffScreen extends ConsumerStatefulWidget {
  const AdminAddStaffScreen({super.key, this.initialRole = AppRole.mentor});

  /// Mentor or administrator. Anything else falls back to mentor, because
  /// graduates join through the course register instead.
  final AppRole initialRole;

  @override
  ConsumerState<AdminAddStaffScreen> createState() =>
      _AdminAddStaffScreenState();
}

class _AdminAddStaffScreenState extends ConsumerState<AdminAddStaffScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  late AppRole _role = const <AppRole>{AppRole.admin, AppRole.guest}
          .contains(widget.initialRole)
      ? widget.initialRole
      : AppRole.mentor;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  /// The database refuses with a stable code; the administrator is told why
  /// in Urdu rather than shown the code.
  static String _describe(Object error) {
    final String text = '$error';
    if (text.contains('INVITE_EMAIL_REGISTERED')) {
      return AppStrings.inviteEmailRegistered;
    }
    // 23505: another administrator invited the same address a moment ago.
    if (text.contains('INVITE_ALREADY_OPEN') || text.contains('23505')) {
      return AppStrings.inviteAlreadyOpen;
    }
    if (text.contains('INVITE_EMAIL_INVALID')) {
      return AppStrings.validationEmail;
    }
    if (text.contains('INVITE_NAME_REQUIRED')) {
      return AppStrings.validationRequired;
    }
    if (text.contains('ADMIN_ONLY')) {
      return AppStrings.adminOnlyAction;
    }
    return '${AppStrings.somethingWentWrong} — $text';
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final StaffInvite invite;
    try {
      invite = await ref.read(adminRepositoryProvider).createStaffInvite(
            fullName: _name.text,
            email: _email.text,
            role: _role,
          );
    } catch (error) {
      setState(() {
        _busy = false;
        _error = _describe(error);
      });
      return;
    }

    ref.invalidate(openStaffInvitesProvider);
    if (!mounted) {
      return;
    }
    await _showCode(invite);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  /// Shows the code the moment it exists, with what to do with it. The same
  /// code stays visible on the staff screen until it is used or withdrawn.
  Future<void> _showCode(StaffInvite invite) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return AlertDialog(
          title: const Text(AppStrings.inviteCreated),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${invite.fullName} — ${AppStrings.invitedAs} '
                  '${invite.role?.urduTitle ?? '—'}',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  invite.email,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.labelSmall,
                ),
                AppSpacing.gapMd,
                InviteCodeCard(invite: invite),
                AppSpacing.gapMd,
                Text(AppStrings.inviteInstructions,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppScaffold(
      title: AppStrings.inviteStaff,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            if (_error != null) ...<Widget>[
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.error),
                ),
              ),
              AppSpacing.gapLg,
            ],
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.goldTint,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Text(
                AppStrings.inviteStaffNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.earthBrown),
              ),
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.staffFullName,
              controller: _name,
              isRequired: true,
              enabled: !_busy,
              prefixIcon: Icons.person_outline,
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
            AppSpacing.gapXl,
            const SectionHeader(title: AppStrings.inviteAs),
            SegmentedButton<AppRole>(
              segments: <ButtonSegment<AppRole>>[
                for (final AppRole role in <AppRole>[
                  AppRole.mentor,
                  AppRole.admin,
                  // A مہمان is invited the same way, and can only view.
                  AppRole.guest,
                ])
                  ButtonSegment<AppRole>(
                    value: role,
                    icon: Icon(role.icon),
                    label: Text(role.urduTitle),
                  ),
              ],
              selected: <AppRole>{_role},
              onSelectionChanged: _busy
                  ? null
                  : (Set<AppRole> selection) =>
                      setState(() => _role = selection.first),
            ),
            AppSpacing.gapSm,
            Text(_role.urduDescription, style: theme.textTheme.labelSmall),
            if (_role == AppRole.admin) ...<Widget>[
              AppSpacing.gapXs,
              Text(
                AppStrings.adminRoleWarning,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.warning),
              ),
            ],
            AppSpacing.gapXl,
            PrimaryButton(
              label: AppStrings.createInvite,
              icon: Icons.mark_email_read_outlined,
              isLoading: _busy,
              onPressed: _busy ? null : _save,
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: AppStrings.cancel,
              // Leaves without inviting anyone.
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
