import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Fallback surface shown by GoRouter's `errorBuilder` for unmatched routes or
/// navigation errors. Keeps the app from ever showing a raw red error screen.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_off_outlined,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Page not found', style: theme.textTheme.headlineSmall),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
