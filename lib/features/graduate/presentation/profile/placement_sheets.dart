import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Shared bottom sheet chrome: a title, and room for the keyboard.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.darkGreen),
              ),
              AppSpacing.gapLg,
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Chooser for the wifaq, which is a curated list.
///
/// Selection only: the administrator maintains this list, and the `wifaqs`
/// policies would reject an insert from an ordinary account anyway.
class WifaqSheet extends ConsumerWidget {
  const WifaqSheet({super.key});

  static Future<WifaqItem?> show(BuildContext context) {
    return showModalBottomSheet<WifaqItem>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => const WifaqSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetFrame(
      title: AppStrings.selectWifaq,
      child: AsyncSection<List<WifaqItem>>(
        value: ref.watch(wifaqListProvider),
        isEmpty: (List<WifaqItem> w) => w.isEmpty,
        emptyTitle: AppStrings.noWifaqsYet,
        emptyIcon: Icons.account_balance_outlined,
        onRetry: () => ref.invalidate(wifaqListProvider),
        builder: (BuildContext context, List<WifaqItem> items) => Column(
          children: <Widget>[
            for (final WifaqItem item in items)
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
                child: AppListTile(
                  title: item.name,
                  subtitle: item.city,
                  icon: Icons.account_balance_outlined,
                  accentColor: AppColors.earthBrown,
                  onTap: () => Navigator.of(context).pop(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chooser for the institute, which a user may add to.
class InstituteSheet extends ConsumerStatefulWidget {
  const InstituteSheet({super.key, required this.wifaq});

  /// The wifaq the institute belongs to. Required, so a newly added institute
  /// is always filed under a board rather than floating free.
  final WifaqItem wifaq;

  static Future<InstituteItem?> show(BuildContext context, WifaqItem wifaq) {
    return showModalBottomSheet<InstituteItem>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => InstituteSheet(wifaq: wifaq),
    );
  }

  @override
  ConsumerState<InstituteSheet> createState() => _InstituteSheetState();
}

class _InstituteSheetState extends ConsumerState<InstituteSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _city = TextEditingController();
  bool _adding = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final InstituteItem created =
          await ref.read(referenceRepositoryProvider).createInstitute(
                name: _name.text,
                wifaqId: widget.wifaq.id,
                city: _city.text,
              );
      ref.invalidate(instituteListProvider(widget.wifaq.id));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('${AppStrings.somethingWentWrong} — $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: AppStrings.selectInstitute,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_adding) ...<Widget>[
            AppFormField(
              label: AppStrings.newInstituteName,
              controller: _name,
              isRequired: true,
              enabled: !_busy,
              prefixIcon: Icons.account_balance_outlined,
            ),
            AppSpacing.gapLg,
            AppFormField(
              label: AppStrings.cityOptional,
              controller: _city,
              enabled: !_busy,
              prefixIcon: Icons.location_city_outlined,
            ),
            AppSpacing.gapLg,
            PrimaryButton(
              label: AppStrings.save,
              icon: Icons.check,
              isLoading: _busy,
              onPressed: _create,
            ),
            AppSpacing.gapSm,
            SecondaryButton(
              label: AppStrings.cancel,
              onPressed: _busy ? null : () => setState(() => _adding = false),
            ),
          ] else ...<Widget>[
            AsyncSection<List<InstituteItem>>(
              value: ref.watch(instituteListProvider(widget.wifaq.id)),
              isEmpty: (List<InstituteItem> i) => i.isEmpty,
              emptyTitle: AppStrings.noInstitutesYet,
              emptyIcon: Icons.account_balance_outlined,
              onRetry: () =>
                  ref.invalidate(instituteListProvider(widget.wifaq.id)),
              builder: (BuildContext context, List<InstituteItem> items) =>
                  Column(
                children: <Widget>[
                  for (final InstituteItem item in items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.sm,
                      ),
                      child: AppListTile(
                        title: item.name,
                        subtitle: item.city,
                        icon: Icons.account_balance_outlined,
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                    ),
                ],
              ),
            ),
            AppSpacing.gapLg,
            SecondaryButton(
              label: AppStrings.addInstitute,
              icon: Icons.add,
              onPressed: () => setState(() => _adding = true),
            ),
          ],
        ],
      ),
    );
  }
}
