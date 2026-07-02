import 'package:flutter/material.dart';

/// Brand color tokens.
///
/// We drive the Material 3 [ColorScheme] from a single [seed] so light and dark
/// palettes stay harmonically related, then expose a few brand-specific colors
/// used outside the scheme (e.g. success/warning states, gradients).
///
/// Keep raw hex values ONLY in this file — everywhere else consumes
/// `Theme.of(context).colorScheme` or [AppColors] semantic getters.
abstract final class AppColors {
  const AppColors._();

  /// Primary brand seed — a refined indigo/violet that reads as premium in
  /// both light and dark. All scheme roles are derived from this.
  static const Color seed = Color(0xFF5B5FEF);

  /// Secondary accent seed for tonal contrast (teal).
  static const Color accentSeed = Color(0xFF13C2C2);

  // -- Semantic status colors (outside the tonal scheme) --------------------
  static const Color success = Color(0xFF2FBF71);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);

  // -- Neutral surfaces used for premium layered cards ----------------------
  static const Color lightScrim = Color(0x0F000000);
  static const Color darkScrim = Color(0x1FFFFFFF);
}
