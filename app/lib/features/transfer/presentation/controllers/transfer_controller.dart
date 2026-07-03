import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transfer_providers.dart';
import '../../domain/entities/transfer_item.dart';
import '../../domain/entities/transfer_offer.dart';
import 'transfer_state.dart';

/// Drives the transfer feature UI.
///
/// Loads history on build, listens for incoming offers and live progress, and
/// exposes the actions the screen invokes (send / accept / reject / cancel /
/// clear). Keeps a merged view of active + historical transfers so the list
/// updates as bytes move.
class TransferController extends Notifier<TransferState> {
  StreamSubscription<TransferOffer>? _offerSub;
  StreamSubscription<TransferItem>? _progressSub;

  @override
  TransferState build() {
    ref.onDispose(() {
      _offerSub?.cancel();
      _progressSub?.cancel();
    });
    _listen();
    Future.microtask(_loadHistory);
    return const TransferState();
  }

  Future<void> _loadHistory() async {
    final items = await ref.read(transferRepositoryProvider).history();
    if (!ref.mounted) return;
    state = state.copyWith(history: items);
  }

  void _listen() {
    final repo = ref.read(transferRepositoryProvider);
    _offerSub = repo.incomingOffers().listen((offer) {
      if (ref.mounted) state = state.copyWith(pendingOffer: offer);
    });
    _progressSub = repo.progress().listen(_onProgress);
  }

  void _onProgress(TransferItem item) {
    if (!ref.mounted) return;
    // Replace/insert into the active list; terminal items fall through to
    // history (the repository persists them) and are dropped from active.
    final active = [
      for (final t in state.active)
        if (t.id != item.id) t,
    ];
    if (!item.isTerminal) active.insert(0, item);
    state = state.copyWith(
      active: active,
      history: item.isTerminal
          ? [item, for (final h in state.history) if (h.id != item.id) h]
          : null,
    );
  }

  /// Picks a file and offers it to the user's other devices.
  Future<void> sendFile() async {
    state = state.copyWith(clearError: true);
    final item = await ref.read(transferRepositoryProvider).sendFile();
    if (!ref.mounted) return;
    final notice = switch (item.status) {
      TransferStatus.cancelled => null, // picker dismissed — no noise
      TransferStatus.failed => item.error ?? 'Could not start transfer',
      _ => 'Offered "${item.fileName}" to your devices',
    };
    if (notice != null) state = state.copyWith(notice: notice);
  }

  /// Accepts the pending incoming offer.
  Future<void> acceptPending() async {
    final offer = state.pendingOffer;
    if (offer == null) return;
    state = state.copyWith(clearPendingOffer: true);
    await ref.read(transferRepositoryProvider).accept(offer);
    if (ref.mounted) {
      state = state.copyWith(notice: 'Accepting "${offer.fileName}"…');
    }
  }

  /// Rejects the pending incoming offer.
  Future<void> rejectPending() async {
    final offer = state.pendingOffer;
    if (offer == null) return;
    state = state.copyWith(clearPendingOffer: true);
    await ref.read(transferRepositoryProvider).reject(offer);
  }

  Future<void> cancel(String transferId) =>
      ref.read(transferRepositoryProvider).cancel(transferId);

  Future<void> clearHistory() async {
    await ref.read(transferRepositoryProvider).clearHistory();
    if (ref.mounted) state = state.copyWith(history: const []);
  }

  void consumeNotice() => state = state.copyWith(clearNotice: true);
}
