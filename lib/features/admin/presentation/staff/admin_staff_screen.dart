import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Where an administrator brings in mentors and administrators who are not
/// on the course register, and finds the accounts no other list shows.
///
/// An administrator appears in neither the graduate nor the mentor list, and
/// an account holding no role appears nowhere at all, so both are listed
/// here. Each opens the same administration screen, where the role can be
/// changed.
class AdminStaffScreen extends ConsumerWidget {
  const AdminStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<StaffInvite>> invites =
        ref.watch(openStaffInvitesProvider);
    final AsyncValue<List<AdminUserRow>> users =
        ref.watch(adminAllUsersProvider);
    final List<AdminUserRow> roleless = (users.value ?? const <AdminUserRow>[])
        .where((AdminUserRow r) => r.role == null)
        .toList();

    Future<void> refresh() async {
      ref.invalidate(openStaffInvitesProvider);
      ref.invalidate(adminAllUsersProvider);
      await Future.wait<Object?>(<Future<Object?>>[
        ref.read(openStaffInvitesProvider.future),
        ref.read(adminAllUsersProvider.future),
      ]);
    }

    return AppScaffold(
      title: AppStrings.staffManagement,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            PrimaryButton(
              label: AppStrings.inviteStaff,
              icon: Icons.person_add_alt_outlined,
              onPressed: () => context.goToRoute(AppRoutes.adminAddStaff),
            ),
            AppSpacing.gapXl,
            const SectionHeader(title: AppStrings.openInvites),
            AsyncSection<List<StaffInvite>>(
              value: invites,
              isEmpty: (List<StaffInvite> items) => items.isEmpty,
              emptyTitle: AppStrings.noOpenInvites,
              emptyIcon: Icons.mark_email_unread_outlined,
              onRetry: () => ref.invalidate(openStaffInvitesProvider),
              builder: (BuildContext context, List<StaffInvite> items) =>
                  Column(
                children: <Widget>[
                  for (final StaffInvite invite in items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.md,
                      ),
                      child: _InviteTile(invite: invite),
                    ),
                ],
              ),
            ),
            AppSpacing.gapXl,
            const SectionHeader(title: AppStrings.administrators),
            AsyncSection<List<AdminUserRow>>(
              value: users,
              isEmpty: (List<AdminUserRow> rows) =>
                  !rows.any((AdminUserRow r) => r.role == AppRole.admin),
              emptyTitle: AppStrings.noRecordsYet,
              emptyIcon: Icons.admin_panel_settings_outlined,
              onRetry: () => ref.invalidate(adminAllUsersProvider),
              builder: (BuildContext context, List<AdminUserRow> rows) =>
                  Column(
                children: <Widget>[
                  for (final AdminUserRow row in rows
                      .where((AdminUserRow r) => r.role == AppRole.admin))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.md,
                      ),
                      child: _AccountTile(
                        profile: row.profile,
                        icon: Icons.admin_panel_settings_outlined,
                        accentColor: AppColors.darkGreen,
                      ),
                    ),
                ],
              ),
            ),
            // Only shown when such an account exists. It is a fault to fix,
            // not a normal part of the list.
            if (roleless.isNotEmpty) ...<Widget>[
              AppSpacing.gapXl,
              const SectionHeader(title: AppStrings.accountsWithoutRole),
              Text(AppStrings.accountsWithoutRoleNote,
                  style: theme.textTheme.labelSmall),
              AppSpacing.gapMd,
              for (final AdminUserRow row in roleless)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                  child: _AccountTile(
                    profile: row.profile,
                    icon: Icons.lock_person_outlined,
                    accentColor: AppColors.warning,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One account, opening the administration screen where its role is set.
class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.profile,
    required this.icon,
    required this.accentColor,
  });

  final GraduateSummary profile;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final bool named = profile.name.trim().isNotEmpty;

    return AppListTile(
      // An account created without a name is shown by its email instead.
      title: named
          ? profile.name
          : (profile.email ?? AppStrings.unnamedAccount),
      subtitle: named ? profile.email : null,
      icon: icon,
      accentColor: accentColor,
      onTap: () => context.goToRoute(AppRoutes.adminUser, extra: profile),
    );
  }
}

/// An open invitation: who it is for, as what, and the code to pass on.
class _InviteTile extends ConsumerWidget {
  const _InviteTile({required this.invite});

  final StaffInvite invite;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.cancelInvite),
            content: const Text(AppStrings.cancelInviteQuestion),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.close),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.cancelInvite),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    try {
      await ref.read(adminRepositoryProvider).cancelStaffInvite(invite.id);
      ref.invalidate(openStaffInvitesProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.inviteCancelled)),
        );
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${AppStrings.somethingWentWrong} — $error'),
        ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String invitedOn = invite.createdAt == null
        ? ''
        : ' • ${AppStrings.invitedOn}: ${UrduDates.label(invite.createdAt)}';

    return DashboardCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(invite.role?.icon ?? Icons.person_outline,
                  size: 22, color: AppColors.primaryGreen),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(invite.fullName, style: theme.textTheme.titleSmall),
                    Text(
                      '${AppStrings.invitedAs} '
                      '${invite.role?.urduTitle ?? '—'}$invitedOn',
                      style: theme.textTheme.labelSmall,
                    ),
                    // An address reads left to right even inside Urdu text.
                    Text(
                      invite.email,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.cancelInvite,
                icon: const Icon(Icons.delete_outline, color: AppColors.gray),
                onPressed: () => _cancel(context, ref),
              ),
            ],
          ),
          AppSpacing.gapSm,
          InviteCodeCard(invite: invite),
        ],
      ),
    );
  }
}

/// The invitation code, large, copyable, and laid out left to right the way
/// it is typed.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.invite});

  final StaffInvite invite;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        children: <Widget>[
          Text('${AppStrings.inviteCode}:', style: theme.textTheme.labelMedium),
          AppSpacing.hGapSm,
          Expanded(
            child: SelectableText(
              invite.displayCode,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.darkGreen,
              ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.copyCode,
            icon: const Icon(Icons.copy_rounded,
                size: 20, color: AppColors.primaryGreen),
            onPressed: () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: invite.displayCode));
              messenger
                ..clearSnackBars()
                ..showSnackBar(
                  const SnackBar(content: Text(AppStrings.codeCopied)),
                );
            },
          ),
        ],
      ),
    );
  }
}
