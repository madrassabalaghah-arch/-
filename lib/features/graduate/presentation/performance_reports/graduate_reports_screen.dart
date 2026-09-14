import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
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
        ].join(' • '),
        icon: Icons.description_outlined,
        status: item.status,
        onTap: () => context.push(AppRoutes.graduateReportEditor, extra: item),
      ),
    );
  }
}
