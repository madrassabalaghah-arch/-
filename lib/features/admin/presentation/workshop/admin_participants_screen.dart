import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/app_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/data/course_repository.dart';
import 'participant_file.dart';

/// The course register: who completed the three-month course, and therefore
/// who may create an account.
///
/// Importing is deliberately two steps. The file is read and checked first and
/// the administrator is shown exactly what would happen; nothing is written
/// until they confirm.
class AdminParticipantsScreen extends ConsumerWidget {
  const AdminParticipantsScreen({super.key});

  static Future<void> _import(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CourseRepository repository = ref.read(courseRepositoryProvider);

    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'txt', 'xlsx', 'xlsm', 'xls'],
    );
    if (file == null) {
      return;
    }

    final Uint8List bytes = await file.readAsBytes();

    final ImportPreview preview;
    try {
      final List<List<String>> table = ParticipantFile.read(bytes, file.name);
      final ({List<CandidateRow> rows, bool missingColumns}) parsed =
          ParticipantFile.toCandidates(table);

      if (parsed.missingColumns) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.missingColumnsError)),
          );
        return;
      }
      preview = await repository.validate(parsed.rows);
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${AppStrings.somethingWentWrong} — $error'),
        ));
      return;
    }

    if (!context.mounted) {
      return;
    }

    final bool confirmed = await _showPreview(context, preview) ?? false;
    if (!confirmed) {
      return;
    }

    try {
      final int written =
          await repository.commit(preview: preview, fileName: file.name);
      ref.invalidate(courseParticipantsProvider);
      ref.invalidate(importHistoryProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
            '${AppStrings.importDone}: ${UrduNumbers.fromInt(written)}',
          ),
        ));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${AppStrings.somethingWentWrong} — $error'),
        ));
    }
  }

  /// Shows what the import would do. Returns true only if the administrator
  /// confirms, and confirming is disabled when there is nothing new to add.
  static Future<bool?> _showPreview(
    BuildContext context,
    ImportPreview preview,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(AppStrings.importPreviewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PreviewLine(AppStrings.totalRecords, preview.total),
            _PreviewLine(AppStrings.validRecords, preview.valid),
            _PreviewLine(AppStrings.duplicateRecords, preview.duplicates),
            _PreviewLine(AppStrings.invalidRecords, preview.invalid),
            if (preview.valid == 0) ...<Widget>[
              AppSpacing.gapMd,
              const Text(AppStrings.nothingToImport),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            // Cancel closes this dialog and nothing else: no record is
            // written, and the register is left exactly as it was.
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: preview.valid == 0
                ? null
                : () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.confirmImport),
          ),
        ],
      ),
    );
  }

  static Future<void> _showHistory(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final AsyncValue<List<ImportBatch>> history =
              ref.watch(importHistoryProvider);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SectionHeader(title: AppStrings.importHistory),
                  AsyncSection<List<ImportBatch>>(
                    value: history,
                    isEmpty: (List<ImportBatch> b) => b.isEmpty,
                    emptyTitle: AppStrings.noImportsYet,
                    emptyIcon: Icons.history_outlined,
                    onRetry: () => ref.invalidate(importHistoryProvider),
                    builder: (BuildContext context, List<ImportBatch> items) =>
                        Column(
                      children: <Widget>[
                        for (final ImportBatch batch in items.take(20))
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: AppSpacing.md,
                            ),
                            child: AppListTile(
                              title: batch.fileName,
                              subtitle: '${AppStrings.validRecords}: '
                                  '${UrduNumbers.fromInt(batch.importedRows)}'
                                  '   ${AppStrings.duplicateRecords}: '
                                  '${UrduNumbers.fromInt(batch.duplicateRows)}',
                              detail: '${AppStrings.totalRecords}: '
                                  '${UrduNumbers.fromInt(batch.totalRows)}',
                              icon: Icons.upload_file_outlined,
                              accentColor: AppColors.earthBrown,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<CourseParticipant>(
      title: AppStrings.manageParticipants,
      items: ref.watch(courseParticipantsProvider),
      onRefresh: () => ref.refresh(courseParticipantsProvider.future),
      searchHint: AppStrings.registrationNumber,
      searchText: (CourseParticipant p) =>
          '${p.registrationNumber} ${p.fullName}',
      emptyIcon: Icons.how_to_reg_outlined,
      emptyTitle: AppStrings.noParticipantsYet,
      emptyMessage: AppStrings.fileFormatHint,
      header: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: PrimaryButton(
                label: AppStrings.importFromFile,
                icon: Icons.upload_file_outlined,
                onPressed: () => _import(context, ref),
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: SecondaryButton(
                label: AppStrings.addByForm,
                icon: Icons.person_add_alt_outlined,
                onPressed: () =>
                    context.goToRoute(AppRoutes.adminAddParticipant),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.importHistory,
          icon: const Icon(Icons.history_outlined),
          onPressed: () => _showHistory(context, ref),
        ),
      ],
      itemBuilder: (BuildContext context, CourseParticipant p) => AppListTile(
        title: '${p.registrationNumber} — ${p.fullName}',
        subtitle: p.coursePeriod,
        detail: p.accountCreated
            ? AppStrings.accountCreated
            : AppStrings.accountNotCreated,
        icon: p.accountCreated
            ? Icons.verified_user_outlined
            : Icons.person_outline,
        status: p.eligible ? AppStatus.active : AppStatus.inactive,
        accentColor: p.accountCreated ? AppColors.primaryGreen : AppColors.gray,
        trailing: Switch(
          value: p.eligible,
          onChanged: (bool value) async {
            await ref
                .read(courseRepositoryProvider)
                .setEligible(id: p.id, eligible: value);
            ref.invalidate(courseParticipantsProvider);
          },
        ),
      ),
    );
  }
}

/// One counted line of the import preview.
class _PreviewLine extends StatelessWidget {
  const _PreviewLine(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodyMedium),
          Text(UrduNumbers.fromInt(value), style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
