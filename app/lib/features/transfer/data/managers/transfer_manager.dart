import 'dart:async';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/platform/platform_seams.dart';
import '../../domain/entities/transfer_item.dart';
import '../../domain/entities/transfer_offer.dart';
import 'connection_manager.dart';
import 'encryption_manager.dart';
import 'transfer_socket_manager.dart';

/// Orchestrates a transfer end-to-end (the "Transfer Manager").
///
/// It is the single place the transfer lifecycle lives, composing the other
/// managers:
///   * [TransferSocketManager] — signaling (offer/accept/reject/cancel),
///   * [EncryptionManager]     — per-transfer AES-GCM key + chunk sealing,
///   * [ConnectionManager]     — the direct byte channel,
///   * [TransferSenderBridge]  — native file pick + byte reads.
///
/// Progress and status changes are published on [updates] as immutable
/// [TransferItem]s, which the repository forwards to the controller/UI and
/// records to history.
class TransferManager {
  TransferManager({
    required TransferSocketManager signalingManager,
    required EncryptionManager encryptionManager,
    required ConnectionManager connectionManager,
    required TransferSenderBridge senderBridge,
    required AppLogger appLogger,
    String Function()? idFactory,
  })  : _signaling = signalingManager,
        _encryption = encryptionManager,
        _connection = connectionManager,
        _sender = senderBridge,
        _logger = appLogger,
        _newId = idFactory ?? _defaultId;

  final TransferSocketManager _signaling;
  final EncryptionManager _encryption;
  final ConnectionManager _connection;
  final TransferSenderBridge _sender;
  final AppLogger _logger;
  final String Function() _newId;

  static const int _chunkSize = 64 * 1024;

  final _updates = StreamController<TransferItem>.broadcast();

  /// Live status/progress updates for transfers this manager drives.
  Stream<TransferItem> get updates => _updates.stream;

  /// Picks a file and offers it to the user's other devices.
  ///
  /// Returns the created [TransferItem] in [TransferStatus.offered]. The byte
  /// transfer itself begins when a peer accepts (see [onAccepted]); until then
  /// the file only exists as a pending offer.
  Future<TransferItem?> pickAndOffer() async {
    final picked = await _sender.pickFile();
    if (picked == null) return null; // user cancelled
    return offerFile(picked);
  }

  /// Offers an already-resolved [file] (from the picker or the share sheet) to
  /// the user's other devices. Shared entry point for both send paths.
  Future<TransferItem> offerFile(PickedFile file) async {
    final item = TransferItem(
      id: _newId(),
      fileName: file.name,
      size: file.size,
      contentType: file.contentType,
      direction: TransferDirection.outgoing,
      status: TransferStatus.offered,
      createdAt: DateTime.now(),
    );
    _emit(item);
    _pendingFiles[item.id] = file;

    final acked = await _signaling.offer(
      transferId: item.id,
      fileName: item.fileName,
      size: item.size,
      contentType: item.contentType,
    );
    if (!acked) {
      final failed = item.copyWith(
        status: TransferStatus.failed,
        error: 'Could not reach your other devices',
      );
      _emit(failed);
      _pendingFiles.remove(item.id);
      return failed;
    }
    return item;
  }

  /// Files picked but not yet sent, keyed by transfer id.
  final Map<String, PickedFile> _pendingFiles = {};

  /// Called when a peer accepts an outgoing offer: streams the file bytes,
  /// encrypting each chunk before it leaves the device.
  Future<void> onAccepted(TransferItem item, {String? descriptor}) async {
    final picked = _pendingFiles.remove(item.id);
    if (picked == null) return;

    var current = item.copyWith(status: TransferStatus.active);
    _emit(current);

    try {
      final key = await _encryption.generateKey();
      await _connection.open(descriptor ?? item.id);

      var sent = 0;
      await for (final chunk
          in _sender.openRead(picked.id, chunkSize: _chunkSize)) {
        final sealed = await _encryption.seal(key, chunk);
        await _connection.send(sealed.bytes);
        sent += chunk.length;
        current = current.copyWith(bytesTransferred: sent);
        _emit(current);
      }

      await _connection.close();
      await _signaling.complete(item.id, ok: true);
      _emit(current.copyWith(status: TransferStatus.completed));
    } catch (e, s) {
      _logger.warn('[transfer] send failed for ${item.id}', error: e, stackTrace: s);
      await _signaling.complete(item.id, ok: false);
      _emit(current.copyWith(
        status: TransferStatus.failed,
        error: e is UnimplementedError ? e.message : 'Transfer failed',
      ));
    }
  }

  /// Accepts an incoming [offer]; the actual receive is a native seam.
  Future<TransferItem> acceptOffer(TransferOffer offer) async {
    await _signaling.acceptOffer(offer.transferId, sdp: offer.sdp);
    final item = _fromOffer(offer, TransferStatus.accepted);
    _emit(item);
    return item;
  }

  Future<void> rejectOffer(TransferOffer offer, {String? reason}) async {
    await _signaling.rejectOffer(offer.transferId, reason: reason);
    _emit(_fromOffer(offer, TransferStatus.rejected));
  }

  Future<void> cancel(String transferId, {String? reason}) async {
    await _signaling.cancel(transferId, reason: reason);
    _pendingFiles.remove(transferId);
  }

  void dispose() => _updates.close();

  // -- helpers -------------------------------------------------------------

  void _emit(TransferItem item) {
    if (!_updates.isClosed) _updates.add(item);
  }

  TransferItem _fromOffer(TransferOffer offer, TransferStatus status) =>
      TransferItem(
        id: offer.transferId,
        fileName: offer.fileName,
        size: offer.size,
        contentType: offer.contentType,
        direction: TransferDirection.incoming,
        status: status,
        peerDeviceId: offer.fromDeviceId,
        createdAt: offer.receivedAt,
      );

  static String _defaultId() =>
      't${DateTime.now().microsecondsSinceEpoch}';
}
