import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/urdu_numbers.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import 'csv_import.dart';

/// The workshop register: who attended, who may create an account, and who
/// already has.
///
/// This is the gate for the whole application — nobody outside this list can
/// register — so adding to it is restricted to administrators by the
/// `workshop_participants` policies, not merely by hiding the screen.
class AdminWorkshopScreen extends ConsumerWidget {
  const AdminWorkshopScreen({super.key});

  static void _toast(ScaffoldMessengerState m, String message) {
    m
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Imports a CSV of participants, skipping numbers already on file.
  static Future<void> _import(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['csv', 'txt'],
      );
      if (file == null) {
        return;
      }

      // utf8 with malformed characters allowed, because spreadsheets export
      // Urdu with a byte order mark and occasional stray bytes.
      final String text = utf8.decode(await file.readAsBytes(),
          allowMalformed: true);
      final ({List<Map<String, dynamic>> rows, int invalid}) parsed =
          CsvImport.toParticipants(text);

      if (parsed.rows.isEmpty) {
        _toast(messenger, AppStrings.noRecordsYet);
        return;
      }

      final ({int imported, int skipped}) result = await ref
          .read(workshopRepositoryProvider)
          .importParticipants(parsed.rows);

      ref.invalidate(workshopParticipantsProvider);
      _toast(
        messenger,
        '${AppStrings.importDone} — '
        '${AppStrings.importSummary}: ${UrduNumbers.fromInt(result.imported)}, '
        '${AppStrings.importSkipped}: '
        '${UrduNumbers.fromInt(result.skipped + parsed.invalid)}',
      );
    } catch (error) {
      _toast(messenger, '${AppStrings.somethingWentWrong} — $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchableListScreen<WorkshopParticipant>(
      title: AppStrings.manageWorkshop,
      items: ref.watch(workshopParticipantsProvider),
      onRefresh: () => ref.refresh(workshopParticipantsProvider.future),
      searchHint: AppStrings.registrationNumber,
      searchText: (WorkshopParticipant p) =>
          '${p.registrationNumber} ${p.fullName} ${p.batch ?? ''}',
      emptyIcon: Icons.how_to_reg_outlined,
      emptyTitle: AppStrings.noParticipantsYet,
      emptyMessage: AppStrings.csvFormatHint,
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.importParticipants,
          icon: const Icon(Icons.upload_file_outlined),
          onPressed: () => _import(context, ref),
        ),
        IconButton(
          tooltip: AppStrings.addParticipant,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _add(context, ref),
        ),
      ],
      itemBuilder: (BuildContext context, WorkshopParticipant p) => AppListTile(
        title: '${p.registrationNumber} — ${p.fullName}',
        subtitle: <String>[
          p.genderLabel,
          if (p.batch != null) p.batch!,
        ].join(' • '),
        detail: p.accountCreated
            ? AppStrings.accountCreated
            : AppStrings.accountNotCreated,
        icon: p.accountCreated
            ? Icons.verified_user_outlined
            : Icons.person_outline,
        status: !p.eligible
            ? AppStatus.inactive
            : (p.completed ? AppStatus.completed : AppStatus.pending),
        accentColor:
            p.accountCreated ? AppColors.primaryGreen : AppColors.oliveGreen,
        trailing: p.accountCreated
            ? null
            : IconButton(
                tooltip: p.eligible
                    ? AppStrings.retireActivity
                    : AppStrings.restoreActivity,
                icon: Icon(
                  p.eligible ? Icons.toggle_on : Icons.toggle_off_outlined,
                  size: 28,
                  color: p.eligible ? AppColors.primaryGreen : AppColors.gray,
                ),
                onPressed: () async {
                  final ScaffoldMessengerState m =
                      ScaffoldMessenger.of(context);
                  await ref
                      .read(workshopRepositoryProvider)
                      .setFlags(id: p.id, eligible: !p.eligible);
                  ref.invalidate(workshopParticipantsProvider);
                  _toast(m, AppStrings.participantUpdated);
                },
              ),
      ),
    );
  }

  /// Adds a single participant, for the case where one person is registered
  /// after the batch import has already run.
  static Future<void> _add(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController number = TextEditingController();
    final TextEditingController name = TextEditingController();
    final TextEditingController father = TextEditingController();
    final TextEditingController batch = TextEditingController();
    String gender = 'male';

    final bool saved = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setLocal) => AlertDialog(
              title: const Text(AppStrings.addParticipant),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppFormField(
                      label: AppStrings.registrationNumber,
                      hintText: AppStrings.hintRegistrationNumber,
                      controller: number,
                      isRequired: true,
                      prefixIcon: Icons.confirmation_number_outlined,
                    ),
                    AppSpacing.gapLg,
                    AppFormField(
                      label: AppStrings.participantName,
                      controller: name,
                      isRequired: true,
                      prefixIcon: Icons.person_outline,
                    ),
                    AppSpacing.gapLg,
                    AppFormField(
                      label: AppStrings.labelFatherName,
                      controller: father,
                      prefixIcon: Icons.family_restroom_outlined,
                    ),
                    AppSpacing.gapLg,
                    AppFormField(
                      label: AppStrings.workshopBatch,
                      controller: batch,
                      prefixIcon: Icons.groups_outlined,
                    ),
                    AppSpacing.gapLg,
                    // فاضل first, then فاضلہ, matching the order used
                    // everywhere else in the application.
                    SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                            value: 'male', label: Text('فاضل')),
                        ButtonSegment<String>(
                            value: 'female', label: Text('فاضلہ')),
                      ],
                      selected: <String>{gender},
                      onSelectionChanged: (Set<String> v) =>
                          setLocal(() => gender = v.first),
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

    if (!saved || number.text.trim().isEmpty || name.text.trim().isEmpty) {
      number.dispose();
      name.dispose();
      father.dispose();
      batch.dispose();
      return;
    }

    try {
      await ref.read(workshopRepositoryProvider).addParticipant(
            registrationNumber: number.text,
            fullName: name.text,
            fatherName: father.text,
            batch: batch.text,
            gender: gender,
          );
      ref.invalidate(workshopParticipantsProvider);
      _toast(messenger, AppStrings.participantAdded);
    } catch (error) {
      // A duplicate number trips the unique index rather than silently
      // creating a second claimable record.
      _toast(messenger, '${AppStrings.somethingWentWrong} — $error');
    } finally {
      number.dispose();
      name.dispose();
      father.dispose();
      batch.dispose();
    }
  }
}
