import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/device_providers.dart';
import '../../domain/entities/device.dart';
import '../widgets/device_tile.dart';

/// Lists the user's registered devices with refresh, remove and a pairing
/// entry point. Handles loading / error / empty states explicitly.
class RegisteredDevicesScreen extends ConsumerWidget {
  const RegisteredDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(devicesControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.pairDevice),
        icon: const Icon(Icons.add_link),
        label: const Text('Pair device'),
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is Failure ? error.message : 'Failed to load devices',
          onRetry: () => ref.read(devicesControllerProvider.notifier).refresh(),
        ),
        data: (devices) => _DeviceList(devices: devices),
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (devices.isEmpty) {
      return const _EmptyView();
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(devicesControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final device = devices[i];
          return DeviceTile(
            device: device,
            onRemove: () => _confirmRemove(context, ref, device),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove device?'),
        content: Text('“${device.name}” will be signed out and unpaired.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final failure =
        await ref.read(devicesControllerProvider.notifier).revoke(device.deviceId);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text('No devices yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your devices will appear here once registered.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
