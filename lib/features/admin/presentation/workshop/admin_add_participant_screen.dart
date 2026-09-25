import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';
import 'participant_file.dart';

/// Adds participants to the course register one at a time — the in-app
/// alternative to importing a file.
///
/// It applies the same rules as the importer: the رقمِ تسجیل and name are
/// required, a period must carry its year so registration can check it, and a
/// number already on the register is refused with a clear message rather than
/// a database error. "Save and add another" keeps the form open for entering
/// a list by hand.
class AdminAddParticipantScreen extends ConsumerStatefulWidget {
  const AdminAddParticipantScreen({super.key});

  @override
  ConsumerState<AdminAddParticipantScreen> createState() =>
      _AdminAddParticipantScreenState();
}

class _AdminAddParticipantScreenState
    extends ConsumerState<AdminAddParticipantScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _period = TextEditingController();
  final TextEditingController _start = TextEditingController();
  final TextEditingController _end = TextEditingController();

  /// null until the administrator says. It is counted as "not recorded"
  /// rather than assumed either way.
  String? _gender;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _number, _name, _period, _start, _end,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// A period or month is optional, but when given it must say which year,
  /// because that year is what registration compares.
  static String? _needsYear(String? value) =>
      ParticipantFile.isMonthLike(value ?? '') ? null : AppStrings.periodNeedsYear;

  Future<void> _save({required bool addAnother}) async {
    if (!(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (await ref.read(courseRepositoryProvider).participantExists(_number.text)) {
        setState(() {
          _busy = false;
          _error = AppStrings.participantAlreadyExists;
        });
        return;
      }

      await ref.read(courseRepositoryProvider).addParticipant(
            registrationNumber: _number.text,
            fullName: _name.text,
            coursePeriod: _period.text,
            courseStartDate: _start.text,
            courseCompletionDate: _end.text,
            gender: _gender,
          );
      ref.invalidate(courseParticipantsProvider);
      // The register is what کل فاضل / کل فاضلہ are counted from.
      ref.invalidate(adminStatisticsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.participantAdded)),
        );

      if (addAnother) {
        for (final TextEditingController c in <TextEditingController>[
          _number, _name, _period, _start, _end,
        ]) {
          c.clear();
        }
        setState(() {
          _busy = false;
          _gender = null;
        });
      } else {
        Navigator.of(context).maybePop();
      }
    } on PostgrestException catch (error) {
      // 23505: another administrator added the same number a moment ago.
      setState(() {
        _busy = false;
        _error = error.code == '23505'
            ? AppStrings.participantAlreadyExists
            : '${AppStrings.somethingWentWrong} — ${error.message}';
      });
    } catch (error) {
      setState(() {
        _busy = false;
        _error = '${AppStrings.somethingWentWrong} — $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppScaffold(
      title: AppStrings.addParticipant,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.bottomSafeArea,
          ),
          children: <Widget>[
            if (_error != null) ...<Widget>[
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.error),
                ),
              ),
              AppSpacing.gapLg,
            ],
            AppFormField(
              label: AppStrings.registrationNumber,
              hintText: AppStrings.hintRegistrationNumber,
              controller: _number,
              isRequired: true,
              enabled: !_busy,
              prefixIcon: Icons.badge_outlined,
              // Letters or digits are required: punctuation alone would
              // normalise to nothing and could never be matched at signup.
              validator: (String? v) => (v == null ||
                      v.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').isEmpty)
                  ? AppStrings.regRequired
                  : null,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.participantName,
              controller: _name,
              isRequired: true,
              enabled: !_busy,
              prefixIcon: Icons.person_outline,
              validator: AppFormField.requiredValidator,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.coursePeriod,
              hintText: AppStrings.hintCoursePeriod,
              controller: _period,
              enabled: !_busy,
              prefixIcon: Icons.date_range_outlined,
              validator: _needsYear,
            ),
            AppSpacing.gapLg,
            const SectionHeader(title: AppStrings.participantGender),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                // فاضل first, فاضلہ second, then the honest third option.
                ButtonSegment<String>(
                  value: 'male',
                  label: Text(AppStrings.genderMale),
                ),
                ButtonSegment<String>(
                  value: 'female',
                  label: Text(AppStrings.genderFemale),
                ),
                ButtonSegment<String>(
                  value: '',
                  label: Text(AppStrings.genderUnknown),
                ),
              ],
              selected: <String>{_gender ?? ''},
              onSelectionChanged: _busy
                  ? null
                  : (Set<String> selection) => setState(
                        () => _gender =
                            selection.first.isEmpty ? null : selection.first,
                      ),
            ),
            AppSpacing.gapXl,
            const SectionHeader(title: AppStrings.optionalMonths),
            AppFormField(
              label: AppStrings.courseStartMonth,
              controller: _start,
              enabled: !_busy,
              prefixIcon: Icons.event_outlined,
              validator: _needsYear,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.courseCompletionMonth,
              controller: _end,
              enabled: !_busy,
              prefixIcon: Icons.event_available_outlined,
              validator: _needsYear,
            ),
            AppSpacing.gapXl,
            PrimaryButton(
              label: AppStrings.save,
              icon: Icons.check_circle_outline,
              isLoading: _busy,
              onPressed: _busy ? null : () => _save(addAnother: false),
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: AppStrings.saveAndAddAnother,
              icon: Icons.playlist_add_outlined,
              onPressed: _busy ? null : () => _save(addAnother: true),
            ),
            AppSpacing.gapMd,
            SecondaryButton(
              label: AppStrings.cancel,
              // Leaves without saving, back to the register it was opened from.
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
