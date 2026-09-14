import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_card.dart';
import 'error_state.dart';
import 'loading_state.dart';

/// Renders one dashboard section from an [AsyncValue].
///
/// Each section resolves independently, so a slow query never blanks the
/// whole dashboard, and a failing one shows its own error rather than
/// silently rendering nothing.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.builder,
    this.isEmpty,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.onRetry,
  });

  final AsyncValue<T> value;

  /// Builds the section once data has arrived and is not empty.
  final Widget Function(BuildContext context, T data) builder;

  /// Decides whether the loaded data counts as empty.
  final bool Function(T data)? isEmpty;

  /// Urdu heading of the empty state.
  final String? emptyTitle;

  /// Urdu message of the empty state.
  final String? emptyMessage;
  final IconData emptyIcon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const DashboardCard(child: LoadingState(compact: true)),
      error: (Object error, StackTrace stack) => DashboardCard(
        child: ErrorState(compact: true, onRetry: onRetry),
      ),
      data: (T data) {
        final bool empty = isEmpty?.call(data) ?? false;
        if (empty) {
          // One quiet row rather than a tall card: a dashboard can show several
          // empty sections at once, and each should read as a short, kind
          // sentence, not take a screenful.
          return DashboardCard(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Icon(emptyIcon, size: 22, color: AppColors.gray),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        emptyTitle ?? AppStrings.noData,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (emptyMessage != null)
                        Text(
                          emptyMessage!,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return builder(context, data);
      },
    );
  }
}
