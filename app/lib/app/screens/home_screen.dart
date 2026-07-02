import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';

/// Authenticated dashboard placeholder.
///
/// Reachable only when [authStatusProvider] reports `authenticated`. Feature
/// steps replace this with the real dashboard (nearby devices, transfer
/// history, clipboard). It exists now so the router's authenticated branch is
/// exercised and testable.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Dashboard', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Feature modules dock here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
