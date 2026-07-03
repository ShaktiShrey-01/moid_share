import '../../../../core/realtime/socket_manager.dart';
import '../../domain/entities/transfer_offer.dart';

/// The **control plane** for file transfer, layered over the generic
/// [SocketManager] (the "Socket Manager" from the design).
///
/// It knows only signaling — offering a transfer and reacting to the peer's
/// accept/reject/cancel/complete. File bytes never touch this class; they flow
/// over the direct [ConnectionManager] channel. This mirrors how the clipboard
/// feature composes its own protocol on top of the shared socket.
///
/// Outbound (this device → peer):
///   `transfer:offer` / `transfer:accept` / `transfer:reject` /
///   `transfer:cancel` / `transfer:complete`
/// Inbound (peer → this device):
///   `transfer:incoming` / `transfer:accepted` / `transfer:rejected` /
///   `transfer:cancelled` / `transfer:completed`
class TransferSocketManager {
  TransferSocketManager(this._socket);

  final SocketManager _socket;

  // -- inbound streams -----------------------------------------------------

  /// Offers pushed from the user's other devices.
  Stream<TransferOffer> incomingOffers() =>
      _socket.on('transfer:incoming').map(
            (data) => TransferOffer.fromSignal(_asMap(data)),
          );

  /// Emits the `transferId` the peer accepted.
  Stream<String> accepted() => _socket
      .on('transfer:accepted')
      .map((data) => _asMap(data)['transferId'] as String? ?? '');

  /// Emits the `transferId` the peer rejected.
  Stream<String> rejected() => _socket
      .on('transfer:rejected')
      .map((data) => _asMap(data)['transferId'] as String? ?? '');

  /// Emits the `transferId` the peer cancelled.
  Stream<String> cancelled() => _socket
      .on('transfer:cancelled')
      .map((data) => _asMap(data)['transferId'] as String? ?? '');

  // -- outbound (ack-based) ------------------------------------------------

  /// Offers a file. Returns true if the server acked the relay.
  Future<bool> offer({
    required String transferId,
    required String fileName,
    required int size,
    String contentType = 'application/octet-stream',
    String? toDeviceId,
    String? sdp,
  }) =>
      _emit('transfer:offer', {
        'transferId': transferId,
        'fileName': fileName,
        'size': size,
        'contentType': contentType,
        'toDeviceId': toDeviceId,
        'sdp': sdp,
      });

  Future<bool> acceptOffer(String transferId, {String? sdp}) =>
      _emit('transfer:accept', {'transferId': transferId, 'sdp': sdp});

  Future<bool> rejectOffer(String transferId, {String? reason}) =>
      _emit('transfer:reject', {'transferId': transferId, 'reason': reason});

  Future<bool> cancel(String transferId, {String? reason}) =>
      _emit('transfer:cancel', {'transferId': transferId, 'reason': reason});

  Future<bool> complete(String transferId, {required bool ok}) =>
      _emit('transfer:complete', {'transferId': transferId, 'ok': ok});

  Future<bool> _emit(String event, Map<String, dynamic> data) async {
    final ack = await _socket.emitWithAck(event, data);
    return ack?['ok'] == true;
  }

  static Map<String, dynamic> _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
}
