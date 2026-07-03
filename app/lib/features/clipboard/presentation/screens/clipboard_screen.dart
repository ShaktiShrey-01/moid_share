import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/clipboard_providers.dart';
import '../widgets/clipboard_history_tile.dart';

/// Clipboard sync surface: toggle sync, send current clipboard, view history.
class ClipboardScreen extends ConsumerWidget {
  const ClipboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clipboardControllerProvider);
    final controller = ref.read(clipboardControllerProvider.notifier);
    final theme = Theme.of(context);

    ref.listen(
      clipboardControllerProvider.select((s) => s.notice),
      (_, notice) {
        if (notice != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(notice)));
          controller.consumeNotice();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Clipboard')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clipboard sync'),
                    subtitle: Text(
                      state.syncEnabled
                          ? (state.connected ? 'Connected' : 'Connecting…')
                          : 'Off',
                    ),
                    value: state.syncEnabled,
                    onChanged: (on) =>
                        on ? controller.enableSync() : controller.disableSync(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-apply incoming'),
                    subtitle: const Text(
                      'Write items received from other devices to this clipboard',
                    ),
                    value: state.autoApply,
                    onChanged: controller.toggleAutoApply,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: controller.sendCurrentClipboard,
            icon: const Icon(Icons.ios_share),
            label: const Text('Send current clipboard'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('History', style: theme.textTheme.titleMedium),
              if (state.history.isNotEmpty)
                TextButton(
                  onPressed: controller.clearHistory,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Text(
                  'No clipboard items yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...state.history.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ClipboardHistoryTile(
                  entry: e,
                  onCopy: () => controller.applyToClipboard(e),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
