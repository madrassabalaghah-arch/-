import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/application/auth_providers.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../widgets/widgets.dart';

/// The اہم لنکس bottom-navigation destination, shared by all three roles.
///
/// Readers see the active links; an administrator additionally gets the
/// retired ones, an add action, and a switch to retire or restore each entry.
/// The list is curated, so it stays empty until an administrator fills it in
/// rather than showing invented examples.
class ImportantLinksScreen extends ConsumerWidget {
  const ImportantLinksScreen({super.key});

  /// Opens [link] in the device browser, reporting failure rather than
  /// silently doing nothing.
  static Future<void> _open(BuildContext context, ImportantLink link) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Uri? uri = Uri.tryParse(link.url);

    bool opened = false;
    if (uri != null && uri.hasScheme) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!opened) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.couldNotOpenLink)),
        );
    }
  }

  /// Adds a link from a small dialog. Administrators only.
  static Future<void> _addLink(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController title = TextEditingController();
    final TextEditingController url = TextEditingController();
    final TextEditingController detail = TextEditingController();

    final bool saved = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.addLink),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppFormField(
                    label: AppStrings.linkTitle,
                    controller: title,
                    isRequired: true,
                    prefixIcon: Icons.title_outlined,
                  ),
                  AppSpacing.gapLg,
                  AppFormField(
                    label: AppStrings.linkUrl,
                    controller: url,
                    isRequired: true,
                    prefixIcon: Icons.link_outlined,
                  ),
                  AppSpacing.gapLg,
                  AppFormField(
                    label: AppStrings.linkDetail,
                    controller: detail,
                    prefixIcon: Icons.notes_outlined,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                // Cancel closes this dialog only, leaving the screen behind
                // it exactly as it was.
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.save),
              ),
            ],
          ),
        ) ??
        false;

    if (!saved || title.text.trim().isEmpty || url.text.trim().isEmpty) {
      title.dispose();
      url.dispose();
      detail.dispose();
      return;
    }

    // A link without a scheme cannot be opened, so it is refused here rather
    // than stored and then failing in front of every reader.
    final String address = url.text.trim();
    if (!address.startsWith('http://') && !address.startsWith('https://')) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.linkMustBeHttp)),
        );
      title.dispose();
      url.dispose();
      detail.dispose();
      return;
    }

    try {
      await ref.read(referenceRepositoryProvider).createImportantLink(
            title: title.text,
            url: address,
            detail: detail.text,
          );
      ref.invalidate(importantLinksProvider);
      ref.invalidate(allImportantLinksProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.linkAdded)));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${AppStrings.somethingWentWrong} — $error'),
        ));
    } finally {
      title.dispose();
      url.dispose();
      detail.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAdmin = ref.watch(appSessionProvider).value?.isAdmin ?? false;
    final FutureProvider<List<ImportantLink>> source =
        isAdmin ? allImportantLinksProvider : importantLinksProvider;

    return SearchableListScreen<ImportantLink>(
      title: AppStrings.importantLinks,
      items: ref.watch(source),
      onRefresh: () => ref.refresh(source.future),
      showSearch: false,
      searchText: (ImportantLink item) => item.title,
      emptyIcon: Icons.link_outlined,
      emptyTitle: AppStrings.noLinksYet,
      actions: <Widget>[
        if (isAdmin)
          IconButton(
            tooltip: AppStrings.addLink,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addLink(context, ref),
          ),
      ],
      itemBuilder: (BuildContext context, ImportantLink item) => AppListTile(
        title: item.title,
        subtitle: item.detail,
        detail: item.url,
        icon: item.icon,
        accentColor: item.isActive ? AppColors.primaryGreen : AppColors.gray,
        onTap: item.isActive ? () => _open(context, item) : null,
        trailing: isAdmin
            ? Switch(
                value: item.isActive,
                onChanged: (bool active) async {
                  await ref
                      .read(referenceRepositoryProvider)
                      .setImportantLinkStatus(id: item.id, active: active);
                  ref.invalidate(importantLinksProvider);
                  ref.invalidate(allImportantLinksProvider);
                },
              )
            : null,
      ),
    );
  }
}
