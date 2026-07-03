import 'dart:async';

import '../../../../core/platform/platform_seams.dart';
import '../../domain/entities/transfer_item.dart';
import '../../domain/entities/transfer_offer.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/share_bridge.dart';
import '../datasources/transfer_local_datasource.dart';
import '../managers/transfer_manager.dart';
import '../managers/transfer_socket_manager.dart';

/// [TransferRepository] implementation.
///
/// Composes the orchestration ([TransferManager]), signaling
/// ([TransferSocketManager]) and local history ([TransferLocalDataSource]).
/// It also persists every terminal transfer update to history automatically, so
/// the UI's history list stays in sync without extra plumbing.
class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl({
    required TransferManager transferManager,
    required TransferSocketManager signalingManager,
    required TransferLocalDataSource localDataSource,
    required ShareBridge shareBridge,
  })  : _manager = transferManager,
        _signaling = signalingManager,
        _local = localDataSource,
        _share = shareBridge {
    // Record terminal states to history as they occur.
    _sub = _manager.updates.listen((item) {
      if (item.isTerminal) _local.upsert(item);
    });
  }

  final TransferManager _manager;
  final TransferSocketManager _signaling;
  final TransferLocalDataSource _local;
  final ShareBridge _share;
  late final StreamSubscription<TransferItem> _sub;

  @override
  Future<TransferItem> sendFile() async {
    final item = await _manager.pickAndOffer();
    if (item == null) {
      // User cancelled the picker — surface a neutral non-terminal record.
      return TransferItem(
        id: 'cancelled',
        fileName: '',
        size: 0,
        direction: TransferDirection.outgoing,
        status: TransferStatus.cancelled,
        createdAt: DateTime.now(),
      );
    }
    return item;
  }

  @override
  Future<TransferItem> sendSharedFile(PickedFile file) =>
      _manager.offerFile(file);

  @override
  Stream<PickedFile> sharedFiles() => _share.sharedFiles();

  @override
  Future<TransferItem> accept(TransferOffer offer) =>
      _manager.acceptOffer(offer);

  @override
  Future<void> reject(TransferOffer offer, {String? reason}) =>
      _manager.rejectOffer(offer, reason: reason);

  @override
  Future<void> cancel(String transferId, {String? reason}) =>
      _manager.cancel(transferId, reason: reason);

  @override
  Stream<TransferOffer> incomingOffers() => _signaling.incomingOffers();

  @override
  Stream<TransferItem> progress() => _manager.updates;

  @override
  Future<List<TransferItem>> history() async => _local.read();

  @override
  Future<void> record(TransferItem item) => _local.upsert(item);

  @override
  Future<void> clearHistory() => _local.clear();

  void dispose() => _sub.cancel();
}
