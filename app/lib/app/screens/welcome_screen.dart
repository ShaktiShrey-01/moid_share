import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/brand_mark.dart';

/// Unauthenticated landing surface.
///
/// This is a foundation placeholder: it demonstrates the theme system, the
/// persisted theme toggle, and the router guard's unauthenticated target. The
/// sign-in / create-account actions are wired to the auth feature in a later
/// step (disabled here so intent is clear).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () =>
                ref.read(themeModeControllerProvider.notifier).toggle(),
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const BrandMark(size: 84),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppConstants.appName,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Secure, high-speed sharing and clipboard sync between your '
                'Android device and Mac.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _notImplemented(context, 'Sign in'),
                child: const Text('Sign in'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => _notImplemented(context, 'Create account'),
                child: const Text('Create account'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _notImplemented(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action arrives with the auth feature.')),
      );
  }
}
