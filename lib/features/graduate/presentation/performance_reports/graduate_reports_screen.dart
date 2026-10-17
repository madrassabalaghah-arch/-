import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// The graduate's own کارگزاری, optionally narrowed.
///
/// Opened unfiltered it is the complete list. A dashboard summary card or a
/// quick access category opens it narrowed with [filter] or [categoryKey] —
/// the same filter the card counted with, so its number matches these rows.
class GraduateReportsScreen extends ConsumerWidget {
  const GraduateReportsScreen({
    super.key,
    this.filter = KarGuzariFilter.all,
    this.categoryKey,
    this.title,
  });

  final KarGuzariFilter filter;
  final String? categoryKey;

  /// Heading when narrowed; the full list keeps its usual title.
  final String? title;

  bool get _narrowed => filter != KarGuzariFilter.all || categoryKey != null;

  /// Puts one کارگزاری on the کمیونٹی بورڈ, or takes it back off.
  ///
  /// Sharing is explained before it happens, because it is the one action
  /// here that other people can see.
  static Future<void> _toggleShared(
    BuildContext context,
    WidgetRef ref,
    ReportItem item,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool share = item.sharedAt == null;

    if (share) {
      final bool confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text(AppStrings.shareToCommunity),
              content: const Text(AppStrings.shareToCommunityNote),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(AppStrings.shareToCommunity),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) {
        return;
      }
    }

    try {
      await ref
          .read(communityRepositoryProvider)
          .setShared(reportId: item.id, shared: share);
      ref.invalidate(graduateReportsProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(share
              ? AppStrings.sharedToCommunity
              : AppStrings.unsharedFromCommunity),
        ));
    } catch (error) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${AppStrings.somethingWentWrong} — $error'),
        ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ReportItem>> reports =
        ref.watch(graduateReportsProvider);
    final AsyncValue<List<ReportCategory>> categories =
        ref.watch(reportCategoriesProvider);

    final AsyncValue<List<ReportItem>> items;
    if (reports.hasValue && categories.hasValue) {
      items = AsyncValue<List<ReportItem>>.data(filterKarGuzari(
        reports.value!,
        categories.value!,
        filter: filter,
        categoryKey: categoryKey,
      ));
    } else if (reports.hasError) {
      items = AsyncValue<List<ReportItem>>.error(
          reports.error!, reports.stackTrace ?? StackTrace.current);
    } else if (categories.hasError) {
      items = AsyncValue<List<ReportItem>>.error(
          categories.error!, categories.stackTrace ?? StackTrace.current);
    } else {
      items = const AsyncValue<List<ReportItem>>.loading();
    }

    final Map<String, String> categoryTitles = <String, String>{
      for (final ReportCategory c in categories.value ?? <ReportCategory>[])
        c.id: c.title,
    };

    return SearchableListScreen<ReportItem>(
      title: title ?? AppStrings.myReports,
      items: items,
      onRefresh: () => ref.refresh(graduateReportsProvider.future),
      searchHint: AppStrings.hintSearchReport,
      searchText: (ReportItem item) =>
          '${item.title} ${categoryTitles[item.categoryId] ?? ''}',
      emptyIcon: Icons.description_outlined,
      emptyTitle: _narrowed
          ? AppStrings.emptyNothingInCategory
          : AppStrings.emptyFirstKarGuzari,
      actions: <Widget>[
        IconButton(
          tooltip: AppStrings.newReport,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => context.push(AppRoutes.graduateReportEditor),
        ),
      ],
      itemBuilder: (BuildContext context, ReportItem item) => AppListTile(
        title: item.title,
        subtitle: item.summary,
        // Only the parts that exist: a missing category used to print "null".
        detail: <String>[
          if (categoryTitles[item.categoryId] != null)
            categoryTitles[item.categoryId]!,
          item.dateLabel,
          if (item.sharedAt != null) AppStrings.communityBoard,
        ].join(' • '),
        icon: Icons.description_outlined,
        status: item.status,
        // Sharing is the graduate's own decision, one کارگزاری at a time.
        // Nothing reaches the board without this.
        trailing: IconButton(
          tooltip: AppStrings.shareToCommunity,
          icon: Icon(
            item.sharedAt == null
                ? Icons.ios_share_outlined
                : Icons.check_circle_outline,
            color: item.sharedAt == null
                ? AppColors.gray
                : AppColors.primaryGreen,
          ),
          onPressed: () => _toggleShared(context, ref, item),
        ),
        onTap: () => context.push(AppRoutes.graduateReportEditor, extra: item),
      ),
    );
  }
}
