import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/transfer_providers.dart';
import '../../domain/entities/transfer_offer.dart';
import '../widgets/transfer_tile.dart';

/// File-transfer surface: send a file, watch active transfers, review history,
/// and accept/reject incoming offers.
class TransferScreen extends ConsumerWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferControllerProvider);
    final controller = ref.read(transferControllerProvider.notifier);
    final theme = Theme.of(context);

    // Surface transient notices as snackbars.
    ref.listen(
      transferControllerProvider.select((s) => s.notice),
      (_, notice) {
        if (notice != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(notice)));
          controller.consumeNotice();
        }
      },
    );

    // Prompt for incoming offers.
    ref.listen(
      transferControllerProvider.select((s) => s.pendingOffer),
      (_, offer) {
        if (offer != null) _showOfferSheet(context, ref, offer);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        actions: [
          if (state.history.isNotEmpty)
            TextButton(
              onPressed: controller.clearHistory,
              child: const Text('Clear'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.sendFile,
        icon: const Icon(Icons.upload_file),
        label: const Text('Send file'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.active.isNotEmpty) ...[
            Text('Active', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...state.active.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TransferTile(
                  item: t,
                  onCancel: () => controller.cancel(t.id),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('History', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (state.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Text(
                  'No transfers yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...state.history.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TransferTile(item: t),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showOfferSheet(
    BuildContext context,
    WidgetRef ref,
    TransferOffer offer,
  ) {
    final controller = ref.read(transferControllerProvider.notifier);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incoming file',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('${offer.fileName} · ${_formatSize(offer.size)}'),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.rejectPending();
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.acceptPending();
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
