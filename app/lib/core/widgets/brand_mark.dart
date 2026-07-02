import 'package:flutter/material.dart';

/// Reusable Moid-Share brand mark: a rounded gradient tile with the app's
/// initial glyph. Used on the welcome/splash surfaces and empty states.
///
/// Kept dependency-free (pure Material + theme colors) so it renders
/// identically on every platform.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  /// Edge length of the square mark in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.bolt_rounded,
        color: scheme.onPrimary,
        size: size * 0.5,
      ),
    );
  }
}
