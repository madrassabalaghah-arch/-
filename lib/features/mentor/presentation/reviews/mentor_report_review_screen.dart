import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The review form a mentor fills in against a report.
///
/// The evaluation standards come from the centralised administrator data, so
/// the same standards drive the mentor form and the administrator screens.
class MentorReportReviewScreen extends ConsumerStatefulWidget {
  const MentorReportReviewScreen({super.key});

  @override
  ConsumerState<MentorReportReviewScreen> createState() =>
      _MentorReportReviewScreenState();
}

class _MentorReportReviewScreenState
    extends ConsumerState<MentorReportReviewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, double> _scores = <String, double>{};
  final TextEditingController _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  /// Writes the evaluation, its per-standard scores and the report's new
  /// status in one repository call. Row level security rejects this if the
  /// graduate is not assigned to the signed-in mentor.
  Future<void> _submit(ReportItem report, List<StandardItem> standards) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(mentorRepositoryProvider).submitEvaluation(
            reportId: report.id,
            graduateId: report.graduateId,
            comment: _comment.text.trim(),
            maxScore: standards.fold<int>(
                0, (int sum, StandardItem s) => sum + s.weight),
            scoresByStandard: <String, int>{
              for (final StandardItem s in standards)
                s.id: (_scores[s.id] ?? 0).round(),
            },
          );
      ref.invalidate(mentorReportsProvider);
      ref.invalidate(mentorEvaluationsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
            const SnackBar(content: Text(AppStrings.submitSuccess)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
            content: Text('${AppStrings.somethingWentWrong} — $error')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<StandardItem> standards =
        ref.watch(adminStandardsProvider).value ?? const <StandardItem>[];
    final List<ReportItem> reports =
        ref.watch(mentorReportsProvider).value ?? const <ReportItem>[];

    return AppScaffold(
      title: AppStrings.reportReview,
      body: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            if (reports.isNotEmpty)
              DashboardCard(
                variant: DashboardCardVariant.info,
                accentColor: AppColors.tealGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      reports.first.title,
                      style: theme.textTheme.titleSmall,
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      '${AppStrings.graduateName}: '
                      '${reports.first.graduateName}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            AppSpacing.gapXl,
            const SectionHeader(title: AppStrings.standards),
            for (final StandardItem standard in standards) ...<Widget>[
              _StandardSlider(
                standard: standard,
                value: _scores[standard.id] ?? 0,
                onChanged: (double value) =>
                    setState(() => _scores[standard.id] = value),
              ),
              AppSpacing.gapMd,
            ],
            AppSpacing.gapMd,
            const SectionHeader(title: AppStrings.labelReviewNote),
            AppFormField(
              label: AppStrings.labelReviewNote,
              hintText: AppStrings.hintReportDetail,
              controller: _comment,
              maxLines: 5,
              isRequired: true,
              enabled: !_busy,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapXl,
            PrimaryButton(
              label: AppStrings.submit,
              icon: Icons.check_circle_outline,
              isLoading: _busy,
              onPressed: reports.isEmpty
                  ? null
                  : () => _submit(reports.first, standards),
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: AppStrings.cancel,
              onPressed: _busy ? null : () => setState(_scores.clear),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single evaluation standard with its score slider.
class _StandardSlider extends StatelessWidget {
  const _StandardSlider({
    required this.standard,
    required this.value,
    required this.onChanged,
  });

  final StandardItem standard;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  standard.title,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                UrduNumbers.ratio(value.round(), standard.weight),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AppSpacing.gapXxs,
          Text(standard.detail ?? '', style: theme.textTheme.bodySmall),
          Slider(
            value: value.clamp(0, standard.weight.toDouble()),
            max: standard.weight.toDouble(),
            divisions: standard.weight,
            activeColor: AppColors.primaryGreen,
            inactiveColor: AppColors.lightGray,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
