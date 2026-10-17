import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The two things the brief insists stay the organisation's to decide: how
/// often a کارگزاری is asked for, and what earns a recognition.
///
/// Both are stored rather than compiled in, so a change takes effect at once
/// and never needs a new release.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  static Future<void> _setInterval(
    BuildContext context,
    WidgetRef ref,
    int months,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).setFollowUpInterval(months);
      ref.invalidate(followUpIntervalProvider);
      ref.invalidate(followUpStatusProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.settingSaved)));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${AppStrings.somethingWentWrong} — $error'),
        ));
    }
  }

  static Future<void> _addRule(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController title = TextEditingController();
    final TextEditingController detail = TextEditingController();
    final TextEditingController threshold = TextEditingController(text: '1');
    RecognitionCriterion criterion = RecognitionCriterion.submittedReports;

    final bool saved = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) =>
                AlertDialog(
              title: const Text(AppStrings.addRecognitionRule),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppFormField(
                      label: AppStrings.ruleTitle,
                      controller: title,
                      isRequired: true,
                      prefixIcon: Icons.workspace_premium_outlined,
                    ),
                    AppSpacing.gapLg,
                    AppFormField(
                      label: AppStrings.ruleDetail,
                      controller: detail,
                      prefixIcon: Icons.notes_outlined,
                    ),
                    AppSpacing.gapLg,
                    DropdownButtonFormField<RecognitionCriterion>(
                      initialValue: criterion,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: AppStrings.ruleCriterion,
                      ),
                      items: <DropdownMenuItem<RecognitionCriterion>>[
                        for (final RecognitionCriterion c
                            in RecognitionCriterion.values)
                          DropdownMenuItem<RecognitionCriterion>(
                            value: c,
                            child: Text(c.urduLabel),
                          ),
                      ],
                      onChanged: (RecognitionCriterion? value) =>
                          setDialogState(() => criterion = value ?? criterion),
                    ),
                    AppSpacing.gapLg,
                    AppFormField(
                      label: AppStrings.ruleThreshold,
                      controller: threshold,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.numbers_outlined,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(AppStrings.save),
                ),
              ],
            ),
          ),
        ) ??
        false;

    final int? count = int.tryParse(threshold.text.trim());
    if (!saved || title.text.trim().isEmpty || count == null || count < 1) {
      title.dispose();
      detail.dispose();
      threshold.dispose();
      return;
    }

    try {
      await ref.read(adminRepositoryProvider).createRecognitionRule(
            title: title.text,
            criterion: criterion,
            threshold: count,
            detail: detail.text,
          );
      ref.invalidate(recognitionRulesProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.ruleAdded)));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${AppStrings.somethingWentWrong} — $error'),
        ));
    } finally {
      title.dispose();
      detail.dispose();
      threshold.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<int> interval = ref.watch(followUpIntervalProvider);
    final AsyncValue<List<RecognitionRule>> rules =
        ref.watch(recognitionRulesProvider);

    return AppScaffold(
      title: AppStrings.systemSettings,
      body: ListView(
        padding: const EdgeInsetsDirectional.only(
          bottom: AppSpacing.bottomSafeArea,
        ),
        children: <Widget>[
          const SectionHeader(title: AppStrings.followUpIntervalLabel),
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.followUpIntervalHelp,
                  style: theme.textTheme.bodySmall,
                ),
                AppSpacing.gapLg,
                AsyncSection<int>(
                  value: interval,
                  onRetry: () => ref.invalidate(followUpIntervalProvider),
                  builder: (BuildContext context, int months) => Wrap(
                    spacing: AppSpacing.sm,
                    children: <Widget>[
                      // One, two and three months are the cycles the brief
                      // names. The stored value drives the whole system, so a
                      // different number set directly still works.
                      for (final int option in <int>[1, 2, 3])
                        ChoiceChip(
                          label: Text(
                            '${UrduNumbers.fromInt(option)} '
                            '${AppStrings.monthsUnit}',
                          ),
                          selected: months == option,
                          onSelected: (bool selected) =>
                              _setInterval(context, ref, option),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapXl,
          SectionHeader(
            title: AppStrings.recognitionRules,
            actionLabel: AppStrings.add,
            onAction: () => _addRule(context, ref),
          ),
          AsyncSection<List<RecognitionRule>>(
            value: rules,
            isEmpty: (List<RecognitionRule> r) => r.isEmpty,
            emptyTitle: AppStrings.noRulesYet,
            emptyIcon: Icons.workspace_premium_outlined,
            onRetry: () => ref.invalidate(recognitionRulesProvider),
            builder: (BuildContext context, List<RecognitionRule> items) =>
                Column(
              children: <Widget>[
                for (final RecognitionRule rule in items)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                    child: AppListTile(
                      title: rule.title,
                      subtitle: rule.detail,
                      detail:
                          '${rule.criterion?.urduLabel ?? AppStrings.noData}'
                          ': ${UrduNumbers.fromInt(rule.threshold)}',
                      icon: Icons.workspace_premium_outlined,
                      accentColor: AppColors.gold,
                      status:
                          rule.isActive ? AppStatus.active : AppStatus.inactive,
                      trailing: Switch(
                        value: rule.isActive,
                        onChanged: (bool active) async {
                          await ref
                              .read(adminRepositoryProvider)
                              .setRuleActive(id: rule.id, active: active);
                          ref.invalidate(recognitionRulesProvider);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
