import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/graduate_repository.dart';

/// Creates a new report, or edits an existing draft.
///
/// A submitted report is deliberately not editable here: the mentor may
/// already be reviewing it. Row level security enforces the same rule, so the
/// disabled fields are a courtesy, not the protection.
class ReportEditorScreen extends ConsumerStatefulWidget {
  const ReportEditorScreen({super.key, this.report});

  /// The draft being edited, or null when creating.
  final ReportItem? report;

  @override
  ConsumerState<ReportEditorScreen> createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends ConsumerState<ReportEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _summary;

  String? _activityId;
  bool _busy = false;

  bool get _isEditing => widget.report != null;

  bool get _isLocked =>
      _isEditing && widget.report!.status != AppStatus.draft;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.report?.title ?? '');
    _summary = TextEditingController(text: widget.report?.summary ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save({required bool submit}) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_isEditing && _activityId == null) {
      _toast(AppStrings.selectActivityFirst);
      return;
    }

    setState(() => _busy = true);
    try {
      final GraduateRepository repo = ref.read(graduateRepositoryProvider);
      if (_isEditing) {
        await repo.updateReport(
          id: widget.report!.id,
          title: _title.text.trim(),
          summary: _summary.text.trim(),
          submit: submit,
        );
      } else {
        await repo.createReport(
          title: _title.text.trim(),
          summary: _summary.text.trim(),
          activityId: _activityId,
          submit: submit,
        );
        // Only a submitted report counts towards progress; a draft does not.
        if (submit && _activityId != null) {
          await repo.recordActivityProgress(_activityId!);
        }
      }
      ref.invalidate(graduateTasksProvider);
      ref.invalidate(graduateActivitiesProvider);
      if (!mounted) {
        return;
      }
      _toast(submit ? AppStrings.reportSubmitted : AppStrings.reportSaved);
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        _toast('${AppStrings.somethingWentWrong} — $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.deleteDraft),
            content: const Text(AppStrings.deleteConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  AppStrings.delete,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(graduateRepositoryProvider)
          .deleteReport(widget.report!.id);
      if (!mounted) {
        return;
      }
      _toast(AppStrings.reportDeleted);
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        _toast('${AppStrings.somethingWentWrong} — $error');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<ActivityItem>> activities =
        ref.watch(activityCatalogueProvider);

    return AppScaffold(
      title: _isEditing ? AppStrings.editReport : AppStrings.newReport,
      actions: <Widget>[
        if (_isEditing && !_isLocked)
          IconButton(
            tooltip: AppStrings.deleteDraft,
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : _delete,
          ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            if (_isLocked) ...<Widget>[
              DashboardCard(
                variant: DashboardCardVariant.info,
                accentColor: AppColors.warning,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.lock_outline,
                        size: 18, color: AppColors.warning),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        AppStrings.onlyDraftsEditable,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLg,
            ],
            if (!_isEditing) ...<Widget>[
              const SectionHeader(title: AppStrings.labelSelectActivity),
              AsyncSection<List<ActivityItem>>(
                value: activities,
                isEmpty: (List<ActivityItem> a) => a.isEmpty,
                emptyTitle: AppStrings.noActivitiesAssigned,
                emptyIcon: Icons.volunteer_activism_outlined,
                onRetry: () => ref.invalidate(activityCatalogueProvider),
                builder: (BuildContext context, List<ActivityItem> items) =>
                    Column(
                  children: <Widget>[
                    for (final ActivityItem activity in items)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.sm,
                        ),
                        child: _ActivityChoice(
                          activity: activity,
                          selected: _activityId == activity.id,
                          onTap: _busy
                              ? null
                              : () =>
                                  setState(() => _activityId = activity.id),
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.gapXl,
            ],
            const SectionHeader(title: AppStrings.labelReportTitle),
            AppFormField(
              label: AppStrings.labelReportTitle,
              controller: _title,
              isRequired: true,
              enabled: !_busy && !_isLocked,
              prefixIcon: Icons.title_outlined,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.labelReportDetail,
              hintText: AppStrings.hintReportDetail,
              controller: _summary,
              maxLines: 6,
              isRequired: true,
              enabled: !_busy && !_isLocked,
              validator: (String? value) =>
                  (value == null || value.trim().isEmpty)
                      ? AppStrings.validationReportDetail
                      : null,
            ),
            AppSpacing.gapXl,
            if (!_isLocked) ...<Widget>[
              PrimaryButton(
                label: AppStrings.submitReport,
                icon: Icons.send_outlined,
                isLoading: _busy,
                onPressed: () => _save(submit: true),
              ),
              AppSpacing.gapMd,
              SecondaryButton(
                label: AppStrings.saveDraft,
                icon: Icons.save_outlined,
                onPressed: _busy ? null : () => _save(submit: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A selectable practical activity the report will be filed against.
class _ActivityChoice extends StatelessWidget {
  const _ActivityChoice({
    required this.activity,
    required this.selected,
    required this.onTap,
  });

  final ActivityItem activity;
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
            child: Icon(
              activity.icon,
              size: 20,
              color: selected ? AppColors.primaryGreen : AppColors.gray,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(activity.title, style: theme.textTheme.titleSmall),
                if (activity.detail != null) ...<Widget>[
                  AppSpacing.gapXxs,
                  Text(
                    activity.detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? AppColors.primaryGreen : AppColors.lightGray,
            size: 22,
          ),
        ],
      ),
    );
  }
}
