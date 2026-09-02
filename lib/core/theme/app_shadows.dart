import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Centralised elevation shadows.
///
/// Shadows are intentionally subtle. The design language relies on soft borders
/// and colour separation rather than heavy elevation.
class AppShadows {
  const AppShadows._();

  /// Neutral shadow token the other shadows are derived from.
  static const Color base = AppColors.shadow;

  /// Default shadow for white content cards.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F0D2A1C),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Slightly stronger shadow for emphasised or gradient surfaces.
  static const List<BoxShadow> elevated = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A0D2A1C),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Shadow used behind the bottom navigation bar.
  static const List<BoxShadow> navigation = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, -2),
    ),
  ];

  /// A tinted shadow that matches a brand surface, used under gradient cards.
  static List<BoxShadow> tinted(Color color) => <BoxShadow>[
        BoxShadow(
          color: color.withValues(alpha: 0.24),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
