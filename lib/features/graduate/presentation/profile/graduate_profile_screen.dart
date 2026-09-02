import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/application/auth_providers.dart';
import 'placement_sheets.dart';
import '../../../auth/presentation/sign_out_action.dart';

/// The graduate profile, backed by the `profiles` row and saved for real.
class GraduateProfileScreen extends ConsumerStatefulWidget {
  const GraduateProfileScreen({super.key});

  @override
  ConsumerState<GraduateProfileScreen> createState() =>
      _GraduateProfileScreenState();
}

class _GraduateProfileScreenState extends ConsumerState<GraduateProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};

  bool _busy = false;
  String? _loadedFor;

  // The chosen placement. Held in state because both are picked from sheets
  // rather than typed, and because clearing one must clear the other.
  WifaqItem? _wifaq;
  InstituteItem? _institute;

  @override
  void dispose() {
    for (final TextEditingController c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the controllers once the profile arrives, and again if the
  /// signed-in user changes.
  void _seed(AppUser profile) {
    if (_loadedFor == profile.id) {
      return;
    }
    _loadedFor = profile.id;
    for (final String key in <String>[
      'full_name',
      'father_name',
      'city',
      'phone',
      'email',
    ]) {
      _fields[key] ??= TextEditingController();
    }
    _fields['full_name']!.text = profile.fullName;
    _fields['father_name']!.text = profile.fatherName ?? '';
    _fields['city']!.text = profile.city ?? '';
    _fields['phone']!.text = profile.phone ?? '';
    _fields['email']!.text = profile.email ?? '';

    _wifaq = profile.wifaqId == null
        ? null
        : WifaqItem(id: profile.wifaqId!, name: profile.wifaqName ?? '');
    _institute = profile.instituteId == null
        ? null
        : InstituteItem(
            id: profile.instituteId!,
            name: profile.instituteName ?? '',
            wifaqId: profile.wifaqId,
          );
  }

  Future<void> _pickWifaq() async {
    final WifaqItem? chosen = await WifaqSheet.show(context);
    if (chosen == null || !mounted) {
      return;
    }
    setState(() {
      _wifaq = chosen;
      // The institute belongs to a wifaq, so changing the board invalidates
      // whatever was chosen under the old one.
      if (_institute?.wifaqId != chosen.id) {
        _institute = null;
      }
    });
  }

  Future<void> _pickInstitute() async {
    final WifaqItem? wifaq = _wifaq;
    if (wifaq == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text(AppStrings.selectWifaqFirst)));
      return;
    }
    final InstituteItem? chosen = await InstituteSheet.show(context, wifaq);
    if (chosen == null || !mounted) {
      return;
    }
    setState(() => _institute = chosen);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(graduateRepositoryProvider).updateProfile(
            fullName: _fields['full_name']!.text.trim(),
            fatherName: _fields['father_name']!.text.trim(),
            city: _fields['city']!.text.trim(),
            phone: _fields['phone']!.text.trim(),
            email: _fields['email']!.text.trim(),
            wifaqId: _wifaq?.id,
            instituteId: _institute?.id,
            updatePlacement: true,
          );
      await ref.read(appSessionProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.saveSuccess)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      // Surface the real reason rather than failing silently.
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('${AppStrings.somethingWentWrong} — $error')),
        );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AppSession?> session = ref.watch(appSessionProvider);

    return AppScaffold(
      title: AppStrings.profile,
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.signOut,
          icon: const Icon(Icons.logout_rounded),
          onPressed: _busy
              ? null
              : () => SignOutAction.confirmAndSignOut(context, ref),
        ),
      ],
      body: session.when(
        loading: () => const LoadingState(message: AppStrings.sessionLoading),
        error: (Object e, StackTrace s) => ErrorState(
          onRetry: () => ref.read(appSessionProvider.notifier).refresh(),
        ),
        data: (AppSession? value) {
          final AppUser? profile = value?.profile;
          if (profile == null) {
            return const EmptyState(
              icon: Icons.person_outline,
              title: AppStrings.sessionLoading,
            );
          }
          _seed(profile);
          return _buildForm(context, profile, value!);
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppUser profile,
    AppSession session,
  ) {
    final ThemeData theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          _ProfileSummary(profile: profile, session: session),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.personalDetails),
          AppFormField(
            label: AppStrings.labelName,
            hintText: AppStrings.hintName,
            controller: _fields['full_name'],
            isRequired: true,
            enabled: !_busy,
            prefixIcon: Icons.person_outline,
            validator: AppFormField.requiredValidator,
          ),
          AppSpacing.gapLg,
          AppFormField(
            label: AppStrings.labelFatherName,
            controller: _fields['father_name'],
            enabled: !_busy,
            prefixIcon: Icons.family_restroom_outlined,
          ),
          AppSpacing.gapLg,
          SelectionField(
            label: AppStrings.labelWifaq,
            value: _wifaq?.name,
            placeholder: AppStrings.noWifaqSelected,
            icon: Icons.verified_outlined,
            enabled: !_busy,
            onTap: _pickWifaq,
          ),
          AppSpacing.gapLg,
          SelectionField(
            label: AppStrings.labelInstitute,
            value: _institute?.name,
            placeholder: _wifaq == null
                ? AppStrings.selectWifaqFirst
                : AppStrings.noInstituteSelected,
            icon: Icons.account_balance_outlined,
            enabled: !_busy && _wifaq != null,
            onTap: _pickInstitute,
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.contactDetails),
          AppFormField(
            label: AppStrings.labelCity,
            hintText: AppStrings.hintCity,
            controller: _fields['city'],
            enabled: !_busy,
            prefixIcon: Icons.location_city_outlined,
          ),
          AppSpacing.gapLg,
          AppFormField(
            label: AppStrings.labelPhone,
            hintText: AppStrings.hintPhone,
            controller: _fields['phone'],
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              return value.trim().length < 11
                  ? AppStrings.validationPhone
                  : null;
            },
          ),
          AppSpacing.gapLg,
          AppFormField(
            label: AppStrings.labelEmail,
            hintText: AppStrings.hintEmail,
            controller: _fields['email'],
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.alternate_email_outlined,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }
              return value.contains('@') ? null : AppStrings.validationEmail;
            },
          ),

          AppSpacing.gapXl,
          PrimaryButton(
            label: AppStrings.save,
            icon: Icons.save_outlined,
            isLoading: _busy,
            onPressed: _save,
          ),
          AppSpacing.gapMd,
          Text(
            '${AppConfig.appNameUrdu} • ${AppConfig.appVersion}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// The green gradient summary block at the top of the profile.
class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile, required this.session});

  final AppUser profile;
  final AppSession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppRole? role = session.primaryRole;

    return DashboardCard(
      variant: DashboardCardVariant.gradient,
      child: Row(
        children: <Widget>[
          Container(
            height: 60,
            width: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.6),
            ),
            child: Text(
              profile.avatarLabel,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: AppColors.white),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  session.displayName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: AppColors.white),
                ),
                AppSpacing.gapXxs,
                Text(
                  <String>[
                    if (role != null) role.urduTitle,
                    if (profile.stage != null) profile.stage!,
                  ].join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.88),
                  ),
                ),
                if (profile.placeLine != null) ...<Widget>[
                  AppSpacing.gapXxs,
                  Text(
                    profile.placeLine!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
