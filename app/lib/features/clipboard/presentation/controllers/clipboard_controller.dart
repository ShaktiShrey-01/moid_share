import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/data/device_providers.dart';
import '../../../../core/realtime/socket_providers.dart';
import '../../data/clipboard_providers.dart';
import '../../domain/entities/clipboard_entry.dart';
import 'clipboard_state.dart';

/// Orchestrates clipboard sync (the "clipboard manager").
///
/// Enabling sync connects the realtime socket, mirrors incoming remote items
/// into history (and optionally the system clipboard), and — where the native
/// bridge supports it — auto-captures local clipboard changes and pushes them
/// to the user's other devices.
class ClipboardController extends Notifier<ClipboardState> {
  StreamSubscription<ClipboardEntry>? _incomingSub;
  StreamSubscription<dynamic>? _systemSub;
  StreamSubscription<bool>? _connectionSub;

  @override
  ClipboardState build() {
    ref.onDispose(() {
      _incomingSub?.cancel();
      _systemSub?.cancel();
      _connectionSub?.cancel();
    });
    Future.microtask(_loadHistory);
    return const ClipboardState();
  }

  Future<void> _loadHistory() async {
    final items = await ref.read(clipboardRepositoryProvider).history();
    if (!ref.mounted) return;
    state = state.copyWith(history: items);
  }

  /// Connects and starts syncing.
  Future<void> enableSync() async {
    if (state.syncEnabled) return;
    state = state.copyWith(clearError: true);

    final identity = await ref.read(deviceIdentityProvider).resolve();
    final socket = ref.read(socketManagerProvider);
    final repo = ref.read(clipboardRepositoryProvider);

    _connectionSub = socket.connectionState.listen((connected) {
      if (ref.mounted) state = state.copyWith(connected: connected);
    });

    await socket.connect(deviceId: identity.deviceId);

    _incomingSub = repo.incoming().listen(_onIncoming);

    // Best-effort native auto-capture; ignore if unsupported on this platform.
    try {
      _systemSub = ref
          .read(clipboardServiceProvider)
          .systemChanges()
          .listen((payload) => _onLocalChange(payload.text));
    } catch (_) {
      // No native change stream here — manual "send" still works.
    }

    state = state.copyWith(syncEnabled: true);
  }

  /// Stops syncing and disconnects.
  Future<void> disableSync() async {
    await _incomingSub?.cancel();
    await _systemSub?.cancel();
    await _connectionSub?.cancel();
    _incomingSub = _systemSub = _connectionSub = null;
    ref.read(socketManagerProvider).disconnect();
    state = state.copyWith(syncEnabled: false, connected: false);
  }

  void toggleAutoApply(bool value) =>
      state = state.copyWith(autoApply: value);

  /// Reads the system clipboard and pushes it to the other devices.
  Future<void> sendCurrentClipboard() async {
    final repo = ref.read(clipboardRepositoryProvider);
    final text = await repo.readSystemClipboard();
    if (text == null || text.trim().isEmpty) {
      state = state.copyWith(notice: 'Clipboard is empty');
      return;
    }
    await _pushAndRecord(text);
  }

  /// Copies a history [entry] back to the system clipboard.
  Future<void> applyToClipboard(ClipboardEntry entry) async {
    await ref.read(clipboardRepositoryProvider).writeSystemClipboard(entry.content);
    state = state.copyWith(notice: 'Copied to clipboard');
  }

  Future<void> clearHistory() async {
    await ref.read(clipboardRepositoryProvider).clearHistory();
    state = state.copyWith(history: const []);
  }

  void consumeNotice() => state = state.copyWith(clearNotice: true);

  // -- internals -----------------------------------------------------------

  Future<void> _onIncoming(ClipboardEntry entry) async {
    final repo = ref.read(clipboardRepositoryProvider);
    await repo.addToHistory(entry);
    if (state.autoApply) {
      await repo.writeSystemClipboard(entry.content);
    }
    if (ref.mounted) {
      state = state.copyWith(history: await repo.history());
    }
  }

  Future<void> _onLocalChange(String text) async {
    if (text.trim().isEmpty) return;
    // Avoid echoing an item we just received/have at the top.
    if (state.history.isNotEmpty && state.history.first.content == text) return;
    await _pushAndRecord(text);
  }

  Future<void> _pushAndRecord(String text) async {
    final repo = ref.read(clipboardRepositoryProvider);
    final ok = await repo.push(text);
    final entry = ClipboardEntry(
      id: 'l${DateTime.now().microsecondsSinceEpoch}',
      content: text,
      origin: ClipboardOrigin.local,
      createdAt: DateTime.now(),
    );
    await repo.addToHistory(entry);
    if (ref.mounted) {
      state = state.copyWith(
        history: await repo.history(),
        notice: ok ? 'Sent to your devices' : 'Saved locally (offline)',
      );
    }
  }
}
