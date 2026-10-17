import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/application/auth_providers.dart';

/// Administration of a single account: its role, and who supervises it.
///
/// Both operations are guarded twice. The screen hides what is not allowed,
/// and the `user_roles` and `mentor_assignments` policies reject the write
/// outright unless `private.is_admin()` is true.
class AdminUserScreen extends ConsumerStatefulWidget {
  const AdminUserScreen({super.key, required this.user});

  final GraduateSummary user;

  @override
  ConsumerState<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends ConsumerState<AdminUserScreen> {
  bool _busy = false;

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminAllUsersProvider);
      ref.invalidate(adminGraduatesProvider);
      ref.invalidate(adminMentorsProvider);
      ref.invalidate(mentorOfProvider(widget.user.id));
      ref.invalidate(graduatesOfProvider(widget.user.id));
      _toast(success);
    } catch (error) {
      _toast(_describe(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// The database refuses with a stable code; the administrator is told why
  /// in Urdu rather than shown the code.
  static String _describe(Object error) {
    final String text = '$error';
    if (text.contains('CANNOT_CHANGE_OWN_ROLE')) {
      return AppStrings.cannotChangeOwnRole;
    }
    if (text.contains('ADMIN_ONLY')) {
      return AppStrings.adminOnlyAction;
    }
    return '${AppStrings.somethingWentWrong} — $text';
  }

  /// Asks before changing a role, and says what else the change will do: the
  /// database ends the assignments that depended on the old role.
  Future<void> _changeRole(AppRole role, AppRole? current) async {
    final bool endsMentoring = current == AppRole.mentor &&
        (ref.read(graduatesOfProvider(widget.user.id)).value?.isNotEmpty ??
            false);
    final bool endsSupervision = current == AppRole.graduate &&
        ref.read(mentorOfProvider(widget.user.id)).value != null;

    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.confirmRoleChange),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${_displayName(widget.user)} — '
                    '${AppStrings.newRole}: ${role.urduTitle}'),
                if (role == AppRole.admin) ...<Widget>[
                  AppSpacing.gapSm,
                  const Text(AppStrings.adminRoleWarning),
                ],
                if (endsMentoring) ...<Widget>[
                  AppSpacing.gapSm,
                  const Text(AppStrings.roleChangeEndsMentoring),
                ],
                if (endsSupervision) ...<Widget>[
                  AppSpacing.gapSm,
                  const Text(AppStrings.roleChangeEndsSupervision),
                ],
                AppSpacing.gapSm,
                const Text(AppStrings.roleChangeNote),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.confirm),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    await _run(
      () => ref
          .read(adminRepositoryProvider)
          .setRole(userId: widget.user.id, role: role),
      AppStrings.roleChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSession? session = ref.watch(appSessionProvider).value;
    final bool isSelf = session?.user.id == widget.user.id;

    final AsyncValue<List<AdminUserRow>> users =
        ref.watch(adminAllUsersProvider);

    // Null means the account genuinely holds no role, and is shown as such.
    // Treating it as a graduate would mark that choice as current and make
    // it impossible to grant.
    AdminUserRow? row;
    for (final AdminUserRow r in users.value ?? const <AdminUserRow>[]) {
      if (r.profile.id == widget.user.id) {
        row = r;
        break;
      }
    }
    final AppRole? currentRole = row?.role;

    return AppScaffold(
      title: AppStrings.manageUser,
      body: ListView(
        children: <Widget>[
          _Identity(user: widget.user, role: currentRole),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.changeRole),
          // Until the roles have loaded, offering choices would mean offering
          // them against a role nobody has read yet.
          if (!users.hasValue)
            AsyncSection<List<AdminUserRow>>(
              value: users,
              onRetry: () => ref.invalidate(adminAllUsersProvider),
              builder: (BuildContext context, List<AdminUserRow> _) =>
                  const SizedBox.shrink(),
            )
          else if (isSelf)
            DashboardCard(
              variant: DashboardCardVariant.info,
              accentColor: AppColors.warning,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.warning),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(AppStrings.cannotChangeOwnRole,
                        style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            )
          else
            Column(
              children: <Widget>[
                for (final AppRole role in AppRole.values)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                    child: _RoleChoice(
                      role: role,
                      selected: role == currentRole,
                      onTap: _busy || role == currentRole
                          ? null
                          : () => _changeRole(role, currentRole),
                    ),
                  ),
                AppSpacing.gapXs,
                Text(AppStrings.roleChangeNote,
                    style: theme.textTheme.labelSmall),
              ],
            ),
          AppSpacing.gapXl,
          if (currentRole == AppRole.graduate) ...<Widget>[
            const SectionHeader(title: AppStrings.assignedMentor),
            _MentorPicker(
              graduateId: widget.user.id,
              busy: _busy,
              onAssign: (String? mentorId) => _run(
                () => ref.read(adminRepositoryProvider).assignMentor(
                      graduateId: widget.user.id,
                      mentorId: mentorId,
                    ),
                mentorId == null
                    ? AppStrings.mentorRemoved
                    : AppStrings.mentorAssigned,
              ),
            ),
          ] else if (currentRole == AppRole.mentor) ...<Widget>[
            const SectionHeader(title: AppStrings.supervisedGraduates),
            AsyncSection<List<GraduateSummary>>(
              value: ref.watch(graduatesOfProvider(widget.user.id)),
              isEmpty: (List<GraduateSummary> g) => g.isEmpty,
              emptyTitle: AppStrings.noGraduatesYet,
              emptyIcon: Icons.groups_outlined,
              builder: (BuildContext context, List<GraduateSummary> items) =>
                  Column(
                children: <Widget>[
                  for (final GraduateSummary g in items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.md),
                      child: AppListTile(
                        title: g.name,
                        subtitle: g.placeLine,
                        avatarText: g.avatarLabel,
                        status: g.status,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The name to show for an account. One created without a name is shown by
/// its email, so it can still be told apart.
String _displayName(GraduateSummary user) {
  if (user.name.trim().isNotEmpty) {
    return user.name;
  }
  return user.email ?? AppStrings.unnamedAccount;
}

/// Name, place and current role of the account being administered.
class _Identity extends StatelessWidget {
  const _Identity({required this.user, required this.role});

  final GraduateSummary user;

  /// Null when the account holds no role.
  final AppRole? role;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DashboardCard(
      variant: DashboardCardVariant.gradient,
      child: Row(
        children: <Widget>[
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1.6),
            ),
            child: Text(
              user.avatarLabel,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: AppColors.white),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_displayName(user),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: AppColors.white)),
                AppSpacing.gapXxs,
                Text(
                  '${AppStrings.currentRole}: '
                  '${role?.urduTitle ?? AppStrings.noRoleYet}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (user.placeLine != null) ...<Widget>[
                  AppSpacing.gapXxs,
                  Text(
                    user.placeLine!,
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

/// One selectable role.
class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final AppRole role;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryGreen.withValues(alpha: 0.14)
                  : AppColors.surfaceSoft,
              borderRadius: AppRadius.radiusSm,
            ),
            child: Icon(role.icon,
                size: 20,
                color: selected ? AppColors.primaryGreen : AppColors.gray),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(role.urduTitle, style: theme.textTheme.titleSmall),
                AppSpacing.gapXxs,
                Text(role.urduDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: selected ? AppColors.primaryGreen : AppColors.lightGray,
            size: 22,
          ),
        ],
      ),
    );
  }
}

/// Shows the graduate's current mentor and lets the administrator change it.
class _MentorPicker extends ConsumerWidget {
  const _MentorPicker({
    required this.graduateId,
    required this.busy,
    required this.onAssign,
  });

  final String graduateId;
  final bool busy;

  /// Called with the chosen mentor, or null to clear the assignment.
  final void Function(String? mentorId) onAssign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<MentorSummary?> current =
        ref.watch(mentorOfProvider(graduateId));
    final AsyncValue<List<MentorSummary>> mentors =
        ref.watch(adminMentorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AsyncSection<MentorSummary?>(
          value: current,
          onRetry: () => ref.invalidate(mentorOfProvider(graduateId)),
          builder: (BuildContext context, MentorSummary? mentor) => AppListTile(
            title: mentor?.name ?? AppStrings.noMentorAssigned,
            subtitle: mentor?.placeLine,
            icon: mentor == null
                ? Icons.person_off_outlined
                : Icons.supervisor_account_outlined,
            accentColor:
                mentor == null ? AppColors.gray : AppColors.primaryGreen,
            trailing: mentor == null
                ? null
                : IconButton(
                    tooltip: AppStrings.removeMentor,
                    icon: const Icon(Icons.link_off, color: AppColors.gray),
                    onPressed: busy ? null : () => onAssign(null),
                  ),
          ),
        ),
        AppSpacing.gapLg,
        const SectionHeader(title: AppStrings.assignMentor),
        AsyncSection<List<MentorSummary>>(
          value: mentors,
          isEmpty: (List<MentorSummary> m) => m.isEmpty,
          emptyTitle: AppStrings.noMentorsAvailable,
          emptyIcon: Icons.supervisor_account_outlined,
          onRetry: () => ref.invalidate(adminMentorsProvider),
          builder: (BuildContext context, List<MentorSummary> items) => Column(
            children: <Widget>[
              for (final MentorSummary mentor in items)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                  child: AppListTile(
                    title: mentor.name,
                    subtitle: mentor.placeLine,
                    avatarText: mentor.avatarLabel,
                    accentColor: AppColors.oliveGreen,
                    onTap: busy || current.value?.id == mentor.id
                        ? null
                        : () => onAssign(mentor.id),
                    trailing: current.value?.id == mentor.id
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primaryGreen, size: 22)
                        : Text(AppStrings.assignMentor,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.primaryGreen)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
