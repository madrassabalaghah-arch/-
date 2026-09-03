import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// The MADRASSA.PK logo, shown on the welcome and authentication screens.
///
/// The artwork is gold calligraphy inside a green dome, so it needs a light
/// ground to read against — hence the white disc rather than the green
/// gradient that stood behind the old placeholder icon. The gold ring keeps
/// the brand's green-and-gold pairing without competing with the mark itself.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 128});

  /// Diameter of the disc.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: size * 0.023),
        boxShadow: AppShadows.tinted(AppColors.primaryGreen),
      ),
      child: Padding(
        // Keeps the calligraphy clear of the ring.
        padding: EdgeInsets.all(size * 0.16),
        child: Image.asset(
          // The mark-only file, not the full lockup: the product name is
          // already rendered as text beneath this, so repeating the caption
          // inside the disc would just make it unreadable.
          'assets/images/logo_mark.png',
          fit: BoxFit.contain,
          errorBuilder: (BuildContext context, Object error, StackTrace? s) =>
              Icon(
            Icons.menu_book_rounded,
            size: size * 0.44,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
}
