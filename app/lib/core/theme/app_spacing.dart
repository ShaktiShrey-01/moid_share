/// Spacing, radius, and elevation tokens on a consistent 4pt grid.
///
/// A single scale keeps layouts rhythmically consistent (the Linear/Notion
/// "everything lines up" feel) and makes global density tweaks trivial.
abstract final class AppSpacing {
  const AppSpacing._();

  /// 2pt — hairline gaps.
  static const double xxs = 2;

  /// 4pt.
  static const double xs = 4;

  /// 8pt.
  static const double sm = 8;

  /// 12pt.
  static const double md = 12;

  /// 16pt — default screen padding.
  static const double lg = 16;

  /// 24pt.
  static const double xl = 24;

  /// 32pt.
  static const double xxl = 32;

  /// 48pt — large section separation.
  static const double xxxl = 48;
}

/// Corner-radius tokens. Rounded, generous corners are core to the premium
/// look; buttons/cards/sheets share this scale for visual coherence.
abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Fully rounded (pills, avatars).
  static const double pill = 999;
}

/// Elevation tokens. We keep elevations low and rely on tonal surface color +
/// subtle shadows rather than heavy drop shadows.
abstract final class AppElevation {
  const AppElevation._();

  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 6;
}
