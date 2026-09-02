import 'package:flutter/widgets.dart';

/// Screen size classes used to adapt layouts.
///
/// Layouts are rebuilt per size class rather than simply stretched, so a tablet
/// shows more columns and wider reading measures instead of a magnified phone
/// layout.
enum ScreenSize {
  /// Small and standard phones.
  compact,

  /// Large phones and small tablets in portrait.
  medium,

  /// Tablets and larger surfaces.
  expanded,
}

/// Responsive breakpoints, aligned with the Material 3 window size classes.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double medium = 600;
  static const double expanded = 905;

  /// Maximum readable content width. On wide screens the content is centred
  /// inside this width instead of stretching edge to edge.
  static const double maxContentWidth = 840;

  static ScreenSize sizeOf(double width) {
    if (width >= expanded) {
      return ScreenSize.expanded;
    }
    if (width >= medium) {
      return ScreenSize.medium;
    }
    return ScreenSize.compact;
  }
}

/// Responsive helpers on [BuildContext].
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  ScreenSize get screenSize => AppBreakpoints.sizeOf(screenWidth);

  bool get isCompact => screenSize == ScreenSize.compact;

  bool get isMedium => screenSize == ScreenSize.medium;

  bool get isExpanded => screenSize == ScreenSize.expanded;

  /// True for very small handsets, where headline sizes are reduced.
  bool get isSmallPhone => screenWidth < 360;

  /// Picks a value for the current size class.
  T responsive<T>({
    required T compact,
    T? medium,
    T? expanded,
  }) {
    switch (screenSize) {
      case ScreenSize.compact:
        return compact;
      case ScreenSize.medium:
        return medium ?? compact;
      case ScreenSize.expanded:
        return expanded ?? medium ?? compact;
    }
  }

  /// Number of columns for statistic and action grids.
  int get gridColumns => responsive<int>(compact: 2, medium: 3, expanded: 4);

  /// Number of columns for larger dashboard cards.
  int get wideGridColumns =>
      responsive<int>(compact: 1, medium: 2, expanded: 3);
}
