import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/presentation/evidence_viewer.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// A mentor's review of one کارگزاری, in the order the work is actually done:
/// read the کارگزاری, look at its evidence, assess it against the standards,
/// write a comment, and give guidance for what comes next.
///
/// [report] is the one that was tapped. This screen used to read the first
/// report in the mentor's queue whatever had been opened, so every review was
/// written against the same report.
class MentorReportReviewScreen extends ConsumerStatefulWidget {
  const MentorReportReviewScreen({required this.report, super.key});

  final ReportItem report;

  @override
  ConsumerState<MentorReportReviewScreen> createState() =>
      _MentorReportReviewScreenState();
}

class _MentorReportReviewScreenState
    extends ConsumerState<MentorReportReviewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _comment = TextEditingController();
  final TextEditingController _guidance = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    _guidance.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Guidance is kept as mentor feedback, which is what the graduate's
  /// dashboard shows under مربی کی رہنمائی.
  Future<void> _sendGuidance() async {
    final String text = _guidance.text.trim();
    if (text.isEmpty) {
      return;
    }
    await ref.read(mentorRepositoryProvider).sendFeedback(
          graduateId: widget.report.graduateId,
          subject: AppStrings.reviewStepGuidance,
          message: text,
          // The کارگزاری under review, so the graduate and the administrator
          // can both see what the guidance was about.
          reportId: widget.report.id,
        );
  }

  /// Completes the review: the written جائزہ, any guidance, and the
  /// report's new status. Row level security refuses it unless the graduate
  /// is assigned to this mentor.
  ///
  /// There is no mark, score or grade here. A جائزہ is appreciation and
  /// guidance in words.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(mentorRepositoryProvider).submitEvaluation(
            reportId: widget.report.id,
            graduateId: widget.report.graduateId,
            comment: _comment.text.trim(),
          );
      await _sendGuidance();
      ref.invalidate(mentorReportsProvider);
      ref.invalidate(mentorEvaluationsProvider);
      if (!mounted) {
        return;
      }
      _toast(AppStrings.submitSuccess);
      Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('${AppStrings.somethingWentWrong} — $error');
      }
    }
  }

  /// Hands the work back. The comment is required, because returning work
  /// without saying why helps nobody.
  Future<void> _requestRevision() async {
    if (_comment.text.trim().isEmpty) {
      _toast(AppStrings.validationRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(mentorRepositoryProvider).requestRevision(
            reportId: widget.report.id,
            graduateId: widget.report.graduateId,
            comment: _comment.text,
          );
      await _sendGuidance();
      ref.invalidate(mentorReportsProvider);
      if (!mounted) {
        return;
      }
      _toast(AppStrings.revisionRequested);
      Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('${AppStrings.somethingWentWrong} — $error');
      }
    }
  }

  Future<void> _judgeEvidence(EvidenceItem item, AppStatus verdict) async {
    try {
      await ref
          .read(mentorRepositoryProvider)
          .reviewEvidence(evidenceId: item.id, verdict: verdict);
      ref.invalidate(reportEvidenceProvider(widget.report.id));
      _toast(AppStrings.evidenceReviewed);
    } catch (error) {
      _toast('${AppStrings.somethingWentWrong} — $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ReportItem report = widget.report;
    final KarGuzariDetails d = report.details;

    return AppScaffold(
      title: AppStrings.reportReview,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            // 1. Read the کارگزاری.
            const _Step(number: 1, title: AppStrings.reviewStepReport),
            DashboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(report.title,
                            style: theme.textTheme.titleMedium),
                      ),
                      StatusBadge(status: report.status, compact: true),
                    ],
                  ),
                  if (report.graduateName != null) ...<Widget>[
                    AppSpacing.gapXs,
                    Text('${AppStrings.graduateName}: ${report.graduateLine}',
                        style: theme.textTheme.labelLarge),
                  ],
                  AppSpacing.gapXxs,
                  Text(report.dateLabel, style: theme.textTheme.labelSmall),
                  if (report.summary != null &&
                      report.summary!.trim().isNotEmpty) ...<Widget>[
                    AppSpacing.gapMd,
                    Text(report.summary!, style: theme.textTheme.bodyMedium),
                  ],
                  // Only the parts the graduate filled in.
                  for (final (String, String?) line in <(String, String?)>[
                    (AppStrings.activityTypeLabel, d.activityType),
                    (AppStrings.locationLabel, d.location),
                    (AppStrings.organisationLabel, d.organisation),
                    (
                      AppStrings.beneficiariesLabel,
                      d.beneficiaries == null
                          ? null
                          : UrduNumbers.fromInt(d.beneficiaries!)
                    ),
                    (AppStrings.learningAppliedLabel, d.learningApplied),
                    (AppStrings.impactLabel, d.impact),
                    (AppStrings.resultsLabel, d.results),
                    (AppStrings.challengesLabel, d.challenges),
                    (AppStrings.futurePlanLabel, d.futurePlan),
                  ])
                    if (line.$2 != null && line.$2!.trim().isNotEmpty) ...<Widget>[
                      AppSpacing.gapSm,
                      Text(line.$1, style: theme.textTheme.labelLarge),
                      Text(line.$2!, style: theme.textTheme.bodyMedium),
                    ],
                ],
              ),
            ),
            AppSpacing.gapXl,

            // 2. Look at the evidence, and give each file a verdict.
            const _Step(number: 2, title: AppStrings.reviewStepEvidence),
            AsyncSection<List<EvidenceItem>>(
              value: ref.watch(reportEvidenceProvider(report.id)),
              isEmpty: (List<EvidenceItem> e) => e.isEmpty,
              emptyTitle: AppStrings.noEvidenceForReport,
              emptyIcon: Icons.folder_open_outlined,
              onRetry: () => ref.invalidate(reportEvidenceProvider(report.id)),
              builder: (BuildContext context, List<EvidenceItem> items) =>
                  Column(
                children: <Widget>[
                  for (final EvidenceItem item in items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.md,
                      ),
                      child: AppListTile(
                        title: item.title,
                        subtitle: '${item.typeLabel} • ${item.reviewLabel}',
                        detail: item.reviewNote ?? item.dateLabel,
                        icon: item.icon,
                        accentColor: AppColors.tealGreen,
                        onTap: () => openEvidence(context, ref, item),
                        trailing: PopupMenuButton<AppStatus>(
                          tooltip: AppStrings.reviewEvidence,
                          icon: const Icon(Icons.fact_check_outlined),
                          onSelected: (AppStatus v) => _judgeEvidence(item, v),
                          itemBuilder: (BuildContext context) =>
                              const <PopupMenuEntry<AppStatus>>[
                            PopupMenuItem<AppStatus>(
                              value: AppStatus.completed,
                              child: Text(AppStrings.evidenceApproved),
                            ),
                            PopupMenuItem<AppStatus>(
                              value: AppStatus.revisionRequired,
                              child: Text(AppStrings.evidenceNeedsInfo),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.gapXl,

            // 3. The mentor's جائزہ, in words.
            const _Step(number: 3, title: AppStrings.reviewStepComment),
            AppFormField(
              label: AppStrings.reviewStepComment,
              hintText: AppStrings.hintReportDetail,
              controller: _comment,
              maxLines: 4,
              isRequired: true,
              enabled: !_busy,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapXl,

            // 4. Guidance for what comes next.
            const _Step(number: 4, title: AppStrings.reviewStepGuidance),
            AppFormField(
              label: AppStrings.reviewStepGuidance,
              hintText: AppStrings.hintGuidance,
              controller: _guidance,
              maxLines: 4,
              enabled: !_busy,
            ),
            AppSpacing.gapXl,

            PrimaryButton(
              label: AppStrings.save,
              icon: Icons.check_circle_outline,
              isLoading: _busy,
              onPressed: _busy ? null : _submit,
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: AppStrings.requestRevision,
              icon: Icons.edit_outlined,
              onPressed: _busy ? null : _requestRevision,
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: AppStrings.cancel,
              // Leaves without saving, back to wherever the review was opened.
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A numbered heading for one step of the review.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: '${UrduNumbers.fromInt(number)}۔ $title');
  }
}
