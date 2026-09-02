import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import 'app_scaffold.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_state.dart';
import 'search_field.dart';

/// A screen showing a searchable list of records loaded from Supabase.
///
/// Takes the [AsyncValue] straight from a provider and renders the loading,
/// error and empty states itself, so every list screen in the application
/// handles those three cases identically and none of them can silently show
/// a blank page.
class SearchableListScreen<T> extends StatefulWidget {
  const SearchableListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.searchText,
    required this.itemBuilder,
    this.onRefresh,
    this.searchHint,
    this.header,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.showSearch = true,
    this.actions,
  });

  /// Urdu title shown in the app bar.
  final String title;

  /// The records, exactly as the provider delivers them.
  final AsyncValue<List<T>> items;

  /// The text a record is matched against while searching.
  final String Function(T item) searchText;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Invoked by pull-to-refresh and by the error state's retry button.
  final Future<void> Function()? onRefresh;

  /// Urdu placeholder for the search field.
  final String? searchHint;

  /// Optional content shown above the list.
  final Widget? header;

  /// Urdu heading of the empty state.
  final String? emptyTitle;

  /// Urdu message of the empty state.
  final String? emptyMessage;
  final IconData emptyIcon;
  final bool showSearch;
  final List<Widget>? actions;

  @override
  State<SearchableListScreen<T>> createState() =>
      _SearchableListScreenState<T>();
}

class _SearchableListScreenState<T> extends State<SearchableListScreen<T>> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<T> _visible(List<T> all) {
    final String query = _query.trim();
    if (query.isEmpty) {
      return all;
    }
    return all
        .where((T item) => widget.searchText(item).contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      actions: widget.actions,
      padBody: false,
      body: widget.items.when(
        loading: () => const LoadingState(),
        error: (Object error, StackTrace stack) => ErrorState(
          onRetry: widget.onRefresh,
        ),
        data: (List<T> all) => _buildList(all),
      ),
    );
  }

  Widget _buildList(List<T> all) {
    final List<T> items = _visible(all);
    final bool isFiltered = _query.trim().isNotEmpty;

    final Widget list = ListView(
      padding: AppSpacing.screenPadding,
      children: <Widget>[
        if (widget.header != null) ...<Widget>[
          widget.header!,
          AppSpacing.gapLg,
        ],
        if (widget.showSearch && all.isNotEmpty) ...<Widget>[
          SearchField(
            controller: _controller,
            hintText: widget.searchHint,
            onChanged: (String value) => setState(() => _query = value),
          ),
          AppSpacing.gapLg,
        ],
        if (items.isEmpty)
          EmptyState(
            icon: widget.emptyIcon,
            title: isFiltered ? AppStrings.noSearchResults : widget.emptyTitle,
            message: isFiltered ? null : widget.emptyMessage,
          )
        else
          for (final T item in items) ...<Widget>[
            widget.itemBuilder(context, item),
            AppSpacing.gapMd,
          ],
      ],
    );

    if (widget.onRefresh == null) {
      return list;
    }
    return RefreshIndicator(
      onRefresh: widget.onRefresh!,
      color: Theme.of(context).colorScheme.primary,
      child: list,
    );
  }
}
