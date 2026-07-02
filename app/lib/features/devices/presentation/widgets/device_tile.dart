import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/device.dart';
import 'platform_icon.dart';

/// List tile rendering a single [Device] with platform icon, status chips and
/// an optional remove action (hidden for the current device).
class DeviceTile extends StatelessWidget {
  const DeviceTile({super.key, required this.device, this.onRemove});

  final Device device;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = device.model ?? device.platform;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              child: Icon(platformIcon(device.platform)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      if (device.isCurrent)
                        _Chip(
                          label: 'This device',
                          color: theme.colorScheme.primaryContainer,
                          onColor: theme.colorScheme.onPrimaryContainer,
                        ),
                      if (device.isPaired)
                        _Chip(
                          label: 'Paired',
                          color: theme.colorScheme.tertiaryContainer,
                          onColor: theme.colorScheme.onTertiaryContainer,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!device.isCurrent && onRemove != null)
              IconButton(
                tooltip: 'Remove device',
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.onColor});

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: onColor),
      ),
    );
  }
}
