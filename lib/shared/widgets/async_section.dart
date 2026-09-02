import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_card.dart';
import 'empty_state.dart';
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
          return DashboardCard(
            child: EmptyState(
              compact: true,
              icon: emptyIcon,
              title: emptyTitle,
              message: emptyMessage,
            ),
          );
        }
        return builder(context, data);
      },
    );
  }
}
