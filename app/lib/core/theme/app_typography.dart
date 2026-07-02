import 'package:flutter/material.dart';

/// Typography scale for Moid-Share.
///
/// Built on the Material 3 type scale with tightened letter-spacing and
/// weights tuned for a modern, editorial feel (Linear/Notion inspired).
///
/// [fontFamily] is intentionally `null` for now, which falls back to the
/// platform's system font (Roboto on Android, SF on Apple) — crisp and free.
/// When a bundled font (e.g. Inter) is added to `pubspec.yaml`, set
/// [fontFamily] here and the whole app updates.
abstract final class AppTypography {
  const AppTypography._();

  static const String? fontFamily = null;

  /// Builds a [TextTheme] for the given [brightness].
  ///
  /// Colors are deliberately omitted so Material can apply the correct
  /// on-surface colors from the active [ColorScheme]; we only shape sizes,
  /// weights and spacing.
  static TextTheme textTheme(Brightness brightness) {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.12,
      ),
      displaySmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    ).apply(fontFamily: fontFamily);
  }
}
