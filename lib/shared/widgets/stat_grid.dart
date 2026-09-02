import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../models/dashboard_items.dart';
import 'stat_card.dart';

/// A responsive grid of statistic cards.
///
/// The column count grows with the screen width, so a tablet shows more figures
/// per row instead of stretching the phone layout.
class StatGrid extends StatelessWidget {
  const StatGrid({
    super.key,
    required this.stats,
    this.onTap,
  });

  final List<StatItem> stats;

  /// Called with the index of the tapped figure.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 146,
      ),
      itemBuilder: (BuildContext context, int index) => StatCard(
        item: stats[index],
        onTap: onTap == null ? null : () => onTap!(index),
      ),
    );
  }
}
