import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/data_providers.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';

/// One کارگزاری or board post, with its عوامی تبصرے underneath.
///
/// Public comments and the نجی جائزہ are two different things and are
/// never shown together: this screen can only read comments, and the
/// database would refuse it a review even if it asked.
class CommunityItemScreen extends ConsumerStatefulWidget {
  const CommunityItemScreen({super.key, required this.item});

  final CommunityItem item;

  @override
  ConsumerState<CommunityItemScreen> createState() =>
      _CommunityItemScreenState();
}

class _CommunityItemScreenState extends ConsumerState<CommunityItemScreen> {
  final TextEditingController _comment = TextEditingController();
  bool _busy = false;

  ({String? reportId, String? postId}) get _target => (
        reportId: widget.item.isKarguzari ? widget.item.id : null,
        postId: widget.item.isKarguzari ? null : widget.item.id,
      );

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addComment() async {
    final String text = _comment.text.trim();
    if (text.isEmpty) {
      _toast(AppStrings.validationRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(communityRepositoryProvider).addComment(
            body: text,
            reportId: _target.reportId,
            postId: _target.postId,
          );
      _comment.clear();
      ref.invalidate(communityCommentsProvider(_target));
      _toast(AppStrings.commentAdded);
    } catch (error) {
      _toast('${AppStrings.somethingWentWrong} — $error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Takes a board post off the board.
  ///
  /// Only offered to an منتظم, and only for a post: a کارگزاری reaches the
  /// board because its owner shared it, and it is theirs to unshare.
  Future<void> _hidePost() async {
    final String? postId = _target.postId;
    if (postId == null) {
      return;
    }
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text(AppStrings.hideFromBoard),
            content: const Text(AppStrings.hidePostConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(AppStrings.hideFromBoard),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    try {
      await ref.read(communityRepositoryProvider).hidePost(postId);
      if (!mounted) {
        return;
      }
      _toast(AppStrings.hiddenFromBoard);
      // true tells the board to load again, so the hidden post goes with it.
      context.pop(true);
    } catch (error) {
      _toast('${AppStrings.somethingWentWrong} — $error');
    }
  }

  Future<void> _hide(CommunityComment comment) async {
    try {
      await ref.read(communityRepositoryProvider).hideComment(comment.id);
      ref.invalidate(communityCommentsProvider(_target));
      _toast(AppStrings.hiddenFromBoard);
    } catch (error) {
      _toast('${AppStrings.somethingWentWrong} — $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CommunityItem item = widget.item;
    final bool isAdmin = ref.watch(appSessionProvider).value?.isAdmin == true;
    final AsyncValue<List<CommunityComment>> comments =
        ref.watch(communityCommentsProvider(_target));

    return AppScaffold(
      title: AppStrings.communityBoard,
      actions: <Widget>[
        if (isAdmin && !item.isKarguzari)
          IconButton(
            tooltip: AppStrings.hideFromBoard,
            icon: const Icon(Icons.visibility_off_outlined),
            onPressed: _busy ? null : _hidePost,
          ),
      ],
      body: ListView(
        padding: const EdgeInsetsDirectional.only(
          bottom: AppSpacing.bottomSafeArea,
        ),
        children: <Widget>[
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: theme.textTheme.titleMedium),
                AppSpacing.gapXs,
                Text(
                  '${item.authorName} — ${item.authorRoleLabel}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.primaryGreen),
                ),
                if (item.groupTitle != null ||
                    item.categoryTitle != null) ...<Widget>[
                  AppSpacing.gapXs,
                  Text(
                    <String>[
                      if (item.groupTitle != null) item.groupTitle!,
                      if (item.categoryTitle != null) item.categoryTitle!,
                    ].join(' • '),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
                if (item.body != null) ...<Widget>[
                  AppSpacing.gapMd,
                  Text(item.body!, style: theme.textTheme.bodyMedium),
                ],
                AppSpacing.gapMd,
                Text(item.dateLabel, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          AppSpacing.gapXl,
          const SectionHeader(title: AppStrings.publicComment),
          Text(AppStrings.publicCommentNote, style: theme.textTheme.labelSmall),
          AppSpacing.gapMd,
          AsyncSection<List<CommunityComment>>(
            value: comments,
            isEmpty: (List<CommunityComment> c) => c.isEmpty,
            emptyTitle: AppStrings.noComments,
            emptyIcon: Icons.chat_bubble_outline,
            onRetry: () => ref.invalidate(communityCommentsProvider(_target)),
            builder: (BuildContext context, List<CommunityComment> items) =>
                Column(
              children: <Widget>[
                for (final CommunityComment c in items)
                  Padding(
                    padding:
                        const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                    child: AppListTile(
                      title: c.authorLine,
                      subtitle: c.body,
                      detail: c.dateLabel,
                      icon: Icons.chat_bubble_outline,
                      accentColor: AppColors.oliveGreen,
                      // Moderation belongs to the منتظم alone; everyone
                      // else simply reads.
                      trailing: isAdmin
                          ? IconButton(
                              tooltip: AppStrings.hideFromBoard,
                              icon: const Icon(Icons.visibility_off_outlined,
                                  color: AppColors.gray),
                              onPressed: () => _hide(c),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFormField(
                  label: AppStrings.publicComment,
                  hintText: AppStrings.publicCommentHint,
                  controller: _comment,
                  maxLines: 3,
                  enabled: !_busy,
                ),
                AppSpacing.gapMd,
                PrimaryButton(
                  label: AppStrings.addComment,
                  icon: Icons.send_outlined,
                  isLoading: _busy,
                  onPressed: _busy ? null : _addComment,
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          // Said plainly, so nobody mistakes this box for the private one.
          Text(AppStrings.privateReviewNote, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
