import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Nearby-devices discovery UI.
///
/// Discovery is a **native seam** (`DiscoveryBridge` in core/platform): Android
/// (mDNS/Nearby via Kotlin) and macOS (Bonjour via Swift) implement it later.
/// Until then this screen presents the intended UI with an explanatory empty
/// state rather than a non-functional scanner.
class NearbyDevicesScreen extends StatelessWidget {
  const NearbyDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby devices')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_tethering,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.lg),
              Text('Scanning for nearby devices',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'On-network discovery activates once the native module is '
                'connected. Use “Pair device” to link a device by code in the '
                'meantime.',
                textAlign: TextAlign.center,
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
