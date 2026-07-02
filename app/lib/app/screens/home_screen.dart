import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/auth/data/auth_providers.dart';

/// Authenticated dashboard. Surfaces the primary features as cards; each opens
/// the relevant screen. Transfer/clipboard cards arrive with those features.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            user == null ? 'Welcome' : 'Welcome, ${user.name}',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Manage your devices and connections.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DashboardCard(
            icon: Icons.devices_outlined,
            title: 'Registered devices',
            subtitle: 'View and manage your devices',
            onTap: () => context.pushNamed(RouteNames.devices),
          ),
          const SizedBox(height: AppSpacing.md),
          _DashboardCard(
            icon: Icons.add_link,
            title: 'Pair a device',
            subtitle: 'Link this device with another by code',
            onTap: () => context.pushNamed(RouteNames.pairDevice),
          ),
          const SizedBox(height: AppSpacing.md),
          _DashboardCard(
            icon: Icons.wifi_tethering,
            title: 'Nearby devices',
            subtitle: 'Discover devices on your network',
            onTap: () => context.pushNamed(RouteNames.nearbyDevices),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
