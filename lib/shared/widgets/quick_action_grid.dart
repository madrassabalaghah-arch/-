import 'package:flutter/material.dart';

import '../../core/routing/app_navigation.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../models/dashboard_items.dart';
import 'dashboard_card.dart';

/// A responsive grid of shortcut tiles.
///
/// Gold tiles are reserved for recognition shortcuts so gold keeps its meaning
/// across the application.
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.actions,
  });

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 124,
      ),
      itemBuilder: (BuildContext context, int index) {
        final QuickAction action = actions[index];
        final Color accent =
            action.isGold ? AppColors.gold : AppColors.primaryGreen;

        return DashboardCard(
          onTap: () => context.goToRoute(action.route),
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Icon(action.icon, size: 20, color: accent),
              ),
              Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }
}
