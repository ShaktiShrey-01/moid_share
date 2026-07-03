import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/transfer_item.dart';

/// Row for one transfer: name, direction, status and a progress bar while
/// active. Used for both the active list and history.
class TransferTile extends StatelessWidget {
  const TransferTile({super.key, required this.item, this.onCancel});

  final TransferItem item;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncoming = item.direction == TransferDirection.incoming;
    final showProgress = switch (item.status) {
      TransferStatus.active || TransferStatus.accepted => true,
      _ => false,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isIncoming ? Icons.download_rounded : Icons.upload_rounded,
              size: 20,
              color: isIncoming
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName.isEmpty ? 'File' : item.fileName,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _subtitle(item),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.size == 0 ? null : item.progress,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onCancel != null && !item.isTerminal)
              IconButton(
                tooltip: 'Cancel',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onCancel,
              ),
          ],
        ),
      ),
    );
  }

  String _subtitle(TransferItem item) {
    final where = item.direction == TransferDirection.incoming
        ? 'From another device'
        : 'To your devices';
    final status = switch (item.status) {
      TransferStatus.offered => 'Offered',
      TransferStatus.accepted => 'Accepted',
      TransferStatus.active => '${(item.progress * 100).round()}%',
      TransferStatus.completed => 'Completed',
      TransferStatus.rejected => 'Rejected',
      TransferStatus.cancelled => 'Cancelled',
      TransferStatus.failed => item.error ?? 'Failed',
    };
    return '$where · $status';
  }
}
