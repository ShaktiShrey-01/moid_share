import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/clipboard_entry.dart';

/// Row for one clipboard history item with an action to copy it back.
class ClipboardHistoryTile extends StatelessWidget {
  const ClipboardHistoryTile({
    super.key,
    required this.entry,
    required this.onCopy,
  });

  final ClipboardEntry entry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRemote = entry.origin == ClipboardOrigin.remote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isRemote ? Icons.download_rounded : Icons.upload_rounded,
              size: 20,
              color: isRemote
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.preview, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isRemote ? 'From another device' : 'From this device',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: onCopy,
            ),
          ],
        ),
      ),
    );
  }
}
