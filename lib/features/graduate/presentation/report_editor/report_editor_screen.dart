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

  /// Which kind of work this is. It is what the dashboard's category counts
  /// and quick access lists are built from.
  String? _categoryId;

  /// The main category chosen on the way to a sub-criterion.
  String? _groupKey;

  /// The fuller record of the activity. Every one of these is optional: a
  /// participant filing quickly should not be blocked, and a blank box is
  /// stored as nothing rather than as an empty string.
  final Map<String, TextEditingController> _extra =
      <String, TextEditingController>{
        for (final String key in <String>[
          'type',
          'location',
          'organisation',
          'beneficiaries',
          'learning',
          'impact',
          'results',
          'challenges',
          'plan',
        ])
          key: TextEditingController(),
      };

  String? _activityId;
  bool _busy = false;

  bool get _isEditing => widget.report != null;

  bool get _isLocked => _isEditing && widget.report!.status != AppStatus.draft;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.report?.title ?? '');
    _summary = TextEditingController(text: widget.report?.summary ?? '');
    _categoryId = widget.report?.categoryId;
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    for (final TextEditingController c in _extra.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Which بنیادی شعبہ is open: the one tapped, or the one the saved
  /// ذیلی معیار belongs to when an existing کارگزاری is reopened.
  String? _selectedGroup(List<ReportCategory> categories) {
    if (_groupKey != null) {
      return _groupKey;
    }
    for (final ReportCategory c in categories) {
      if (c.id == _categoryId) {
        return c.groupKey;
      }
    }
    return null;
  }

  void _chooseGroup(List<ReportCategory> group) {
    setState(() {
      _groupKey = group.first.groupKey;
      // A معیار from the شعبہ just left no longer applies.
      if (!group.any((ReportCategory c) => c.id == _categoryId)) {
        _categoryId = null;
      }
    });
  }

  Future<void> _save({required bool submit}) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_isEditing && _activityId == null) {
      _toast(AppStrings.selectActivityFirst);
      return;
    }
    // The معیار is what the کارگزاری is judged against, so a submission
    // without one comes back here. A draft may still be saved without it.
    if (submit && _categoryId == null) {
      _toast(AppStrings.subCriterionNeeded);
      return;
    }

    setState(() => _busy = true);
    try {
      final GraduateRepository repo = ref.read(graduateRepositoryProvider);
      final KarGuzariDetails details = KarGuzariDetails(
        activityType: _extra['type']!.text,
        location: _extra['location']!.text,
        organisation: _extra['organisation']!.text,
        beneficiaries: int.tryParse(_extra['beneficiaries']!.text.trim()),
        learningApplied: _extra['learning']!.text,
        impact: _extra['impact']!.text,
        results: _extra['results']!.text,
        challenges: _extra['challenges']!.text,
        futurePlan: _extra['plan']!.text,
      );
      if (_isEditing) {
        await repo.updateReport(
          id: widget.report!.id,
          title: _title.text.trim(),
          summary: _summary.text.trim(),
          categoryId: _categoryId,
          details: details,
          submit: submit,
        );
      } else {
        await repo.createReport(
          title: _title.text.trim(),
          summary: _summary.text.trim(),
          activityId: _activityId,
          categoryId: _categoryId,
          details: details,
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
    final bool confirmed =
        await showDialog<bool>(
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
    final AsyncValue<List<ActivityItem>> activities = ref.watch(
      activityCatalogueProvider,
    );

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
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: AppColors.warning,
                    ),
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
                                  : () => setState(
                                      () => _activityId = activity.id,
                                    ),
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
              // The بنیادی شعبہ first, then the ذیلی معیار within it. Both
              // read the same report_categories rows the منتظم maintains — a
              // group is a شعبہ, each row one of its three معیار — so the form
              // and the dashboard can never offer different lists.
              Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  return AsyncSection<List<ReportCategory>>(
                    value: ref.watch(reportCategoriesProvider),
                    isEmpty: (List<ReportCategory> c) => c.isEmpty,
                    emptyTitle: AppStrings.noCategoriesYet,
                    emptyIcon: Icons.category_outlined,
                    onRetry: () => ref.invalidate(reportCategoriesProvider),
                    builder:
                        (
                          BuildContext context,
                          List<ReportCategory> categories,
                        ) {
                          final Map<String, List<ReportCategory>> groups =
                              <String, List<ReportCategory>>{};
                          for (final ReportCategory c in categories) {
                            groups
                                .putIfAbsent(
                                  c.groupKey,
                                  () => <ReportCategory>[],
                                )
                                .add(c);
                          }

                          final String? group = _selectedGroup(categories);
                          final List<ReportCategory> subCriteria =
                              groups[group] ?? const <ReportCategory>[];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const SectionHeader(
                                title: AppStrings.selectMainCategory,
                              ),
                              for (final List<ReportCategory> g
                                  in groups.values)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: _CategoryChoice(
                                    label: g.first.groupTitle,
                                    icon: g.first.groupIcon,
                                    selected: g.first.groupKey == group,
                                    onTap: _busy ? null : () => _chooseGroup(g),
                                  ),
                                ),
                              if (subCriteria.isNotEmpty) ...<Widget>[
                                AppSpacing.gapLg,
                                const SectionHeader(
                                  title: AppStrings.selectSubCriterion,
                                ),
                                for (final ReportCategory c in subCriteria)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: _CategoryChoice(
                                      label: c.title,
                                      icon: c.icon,
                                      selected: c.id == _categoryId,
                                      onTap: _busy
                                          ? null
                                          : () => setState(
                                              () => _categoryId = c.id,
                                            ),
                                    ),
                                  ),
                              ],
                            ],
                          );
                        },
                  );
                },
              ),
              AppSpacing.gapLg,
              const SectionHeader(title: AppStrings.moreDetails),
              for (final ({String key, String label, String? hint, int lines})
                  field
                  in _extraFields) ...<Widget>[
                AppFormField(
                  label: field.label,
                  hintText: field.hint,
                  controller: _extra[field.key],
                  enabled: !_busy,
                  maxLines: field.lines,
                  keyboardType: field.key == 'beneficiaries'
                      ? TextInputType.number
                      : null,
                ),
                AppSpacing.gapLg,
              ],
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

/// One بنیادی شعبہ or one ذیلی معیار, offered as a tappable row.
class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
              icon,
              size: 20,
              color: selected ? AppColors.primaryGreen : AppColors.gray,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
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

/// The optional detail a کارگزاری may carry, in the order the brief lists it.
const List<({String key, String label, String? hint, int lines})> _extraFields =
    <({String key, String label, String? hint, int lines})>[
      (
        key: 'type',
        label: AppStrings.activityTypeLabel,
        hint: AppStrings.activityTypeHint,
        lines: 1,
      ),
      (key: 'location', label: AppStrings.locationLabel, hint: null, lines: 1),
      (
        key: 'organisation',
        label: AppStrings.organisationLabel,
        hint: null,
        lines: 1,
      ),
      (
        key: 'beneficiaries',
        label: AppStrings.beneficiariesLabel,
        hint: null,
        lines: 1,
      ),
      (
        key: 'learning',
        label: AppStrings.learningAppliedLabel,
        hint: null,
        lines: 3,
      ),
      (key: 'impact', label: AppStrings.impactLabel, hint: null, lines: 3),
      (key: 'results', label: AppStrings.resultsLabel, hint: null, lines: 3),
      (
        key: 'challenges',
        label: AppStrings.challengesLabel,
        hint: null,
        lines: 3,
      ),
      (key: 'plan', label: AppStrings.futurePlanLabel, hint: null, lines: 3),
    ];
