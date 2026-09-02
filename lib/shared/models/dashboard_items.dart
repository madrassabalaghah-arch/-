import 'package:flutter/material.dart';

/// Visual tone of a statistic card. Tones map onto the official palette so no
/// screen invents its own colour.
enum StatTone { green, teal, gold, olive, brown, neutral }

/// A single figure on a dashboard.
class StatItem {
  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = StatTone.green,
  });

  /// Urdu label of the figure.
  final String label;

  /// The figure itself, already formatted with Urdu digits.
  final String value;
  final IconData icon;
  final StatTone tone;
}

/// A shortcut tile on a dashboard.
class QuickAction {
  const QuickAction({
    required this.title,
    required this.icon,
    required this.route,
    this.isGold = false,
  });

  /// Urdu title of the shortcut.
  final String title;
  final IconData icon;

  /// Destination route path.
  final String route;

  /// Recognition shortcuts use the gold accent instead of green.
  final bool isGold;
}

/// A management area on the administrator dashboard.
class ManagementArea {
  const ManagementArea({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  /// Urdu title of the management area.
  final String title;

  /// Short Urdu description of what the area contains.
  final String subtitle;
  final IconData icon;
  final String route;
}

/// The graduate training journey summary, computed from real activity rows.
class JourneyProgress {
  const JourneyProgress({
    required this.stageLabel,
    required this.statusLabel,
    required this.completedSteps,
    required this.totalSteps,
    required this.nextStepLabel,
  });

  /// Urdu name of the current training stage, from profiles.stage.
  final String stageLabel;

  /// Urdu description of the current standing.
  final String statusLabel;
  final int completedSteps;
  final int totalSteps;

  /// Urdu description of what comes next.
  final String nextStepLabel;

  double get progress =>
      totalSteps == 0 ? 0 : (completedSteps / totalSteps).clamp(0, 1);

  int get percent => (progress * 100).round();
}
