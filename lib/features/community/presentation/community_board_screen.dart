import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_navigation.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/urdu_numbers.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/data_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';

/// کمیونٹی بورڈ: one shared feed for every role.
///
/// It carries کارگزاری that graduates chose to share and posts written by
/// مربیان and منتظمین, newest first. There is no score, no ranking and no
/// leaderboard here, and a نجی جائزہ never appears: the board reads a
/// database function that cannot see one.
///
/// Pages are loaded as the reader asks for them rather than all at once.
class CommunityBoardScreen extends ConsumerStatefulWidget {
  const CommunityBoardScreen({super.key});

  @override
  ConsumerState<CommunityBoardScreen> createState() =>
      _CommunityBoardScreenState();
}

enum _Filter { all, karguzari, posts }

class _CommunityBoardScreenState extends ConsumerState<CommunityBoardScreen> {
  static const int _pageSize = 20;

  final List<CommunityItem> _items = <CommunityItem>[];
  _Filter _filter = _Filter.all;
  bool _loading = true;
  bool _reachedEnd = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final List<CommunityItem> page =
          await ref.read(communityRepositoryProvider).feed(
                limit: _pageSize,
                // Continue from the oldest row already shown.
                before: reset || _items.isEmpty ? null : _items.last.createdAt,
              );
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          _items.clear();
          _reachedEnd = false;
        }
        _items.addAll(page);
        _reachedEnd = page.length < _pageSize;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  List<CommunityItem> get _visible {
    switch (_filter) {
      case _Filter.karguzari:
        return _items.where((CommunityItem i) => i.isKarguzari).toList();
      case _Filter.posts:
        return _items.where((CommunityItem i) => !i.isKarguzari).toList();
      case _Filter.all:
        return _items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSession? session = ref.watch(appSessionProvider).value;
    // Only a مربی or منتظم may write straight to the board; a فاضل /
    // فاضلہ comments instead, so they are never shown a dead button.
    final bool canPost = session?.isMentor == true || session?.isAdmin == true;
    final List<CommunityItem> items = _visible;

    return AppScaffold(
      title: AppStrings.communityBoard,
      actions: <Widget>[
        if (canPost)
          IconButton(
            tooltip: AppStrings.newPost,
            icon: const Icon(Icons.post_add_outlined),
            onPressed: () async {
              context.goToRoute(AppRoutes.communityNewPost);
            },
          ),
      ],
      padBody: false,
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: <Widget>[
            Text(AppStrings.communityBoardSubtitle,
                style: theme.textTheme.labelSmall),
            AppSpacing.gapMd,
            _FilterBar(
              value: _filter,
              onChanged: (_Filter f) => setState(() => _filter = f),
            ),
            AppSpacing.gapLg,
            if (_loading && _items.isEmpty)
              const LoadingState()
            else if (_error != null && _items.isEmpty)
              ErrorState(onRetry: () => _load(reset: true))
            else if (items.isEmpty)
              const EmptyState(
                icon: Icons.forum_outlined,
                title: AppStrings.communityEmpty,
              )
            else ...<Widget>[
              for (final CommunityItem item in items)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                  child: _FeedTile(
                    item: item,
                    // Pushed from here rather than through goToRoute,
                    // because the board has to know when an منتظم hides a
                    // post while it is open.
                    onTap: () async {
                      final bool? hidden = await context.push<bool>(
                        AppRoutes.communityItem,
                        extra: item,
                      );
                      if (hidden ?? false) {
                        await _load(reset: true);
                      }
                    },
                  ),
                ),
              if (!_reachedEnd && _filter == _Filter.all)
                SecondaryButton(
                  label: AppStrings.communityLoadMore,
                  icon: Icons.expand_more_rounded,
                  onPressed: _loading ? null : () => _load(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// تمام سرگرمیاں / کارگزاریاں / مربیوں کی پوسٹس.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_Filter>(
      segments: const <ButtonSegment<_Filter>>[
        ButtonSegment<_Filter>(
          value: _Filter.all,
          label: Text(AppStrings.communityAll),
        ),
        ButtonSegment<_Filter>(
          value: _Filter.karguzari,
          label: Text(AppStrings.communityKarguzari),
        ),
        ButtonSegment<_Filter>(
          value: _Filter.posts,
          label: Text(AppStrings.communityPosts),
        ),
      ],
      selected: <_Filter>{value},
      onSelectionChanged: (Set<_Filter> s) => onChanged(s.first),
    );
  }
}

/// One row of the board. The author is named, as they are on the screen it
/// opens.
class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item, required this.onTap});

  final CommunityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String category = <String>[
      if (item.groupTitle != null) item.groupTitle!,
      if (item.categoryTitle != null) item.categoryTitle!,
    ].join(' • ');

    return AppListTile(
      title: item.title,
      subtitle: '${item.authorName} — ${item.authorRoleLabel}',
      detail: <String>[
        if (category.isNotEmpty) category,
        item.dateLabel,
        if (item.commentCount > 0)
          '${AppStrings.publicComment}: '
              '${UrduNumbers.fromInt(item.commentCount)}',
      ].join(' • '),
      icon: item.icon,
      accentColor:
          item.isKarguzari ? AppColors.primaryGreen : AppColors.earthBrown,
      onTap: onTap,
    );
  }
}
