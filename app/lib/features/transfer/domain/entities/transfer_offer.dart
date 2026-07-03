/// An incoming transfer offer relayed from one of the user's other devices.
///
/// Produced by the signaling channel (`transfer:incoming`). The UI surfaces it
/// as an accept/reject prompt; accepting begins the byte transfer over the
/// direct connection.
class TransferOffer {
  const TransferOffer({
    required this.transferId,
    required this.fileName,
    required this.size,
    required this.fromDeviceId,
    required this.receivedAt,
    this.contentType = 'application/octet-stream',
    this.sdp,
  });

  final String transferId;
  final String fileName;
  final int size;
  final String contentType;
  final String fromDeviceId;

  /// Opaque connection-negotiation blob (e.g. address/port or WebRTC SDP)
  /// carried through signaling for the direct byte channel. Transport-specific;
  /// the control plane treats it as opaque.
  final String? sdp;
  final DateTime receivedAt;

  static TransferOffer fromSignal(Map<String, dynamic> map) => TransferOffer(
        transferId: map['transferId'] as String? ?? '',
        fileName: map['fileName'] as String? ?? 'file',
        size: (map['size'] as num?)?.toInt() ?? 0,
        contentType:
            map['contentType'] as String? ?? 'application/octet-stream',
        fromDeviceId: map['fromDeviceId'] as String? ?? 'unknown',
        sdp: map['sdp'] as String?,
        receivedAt:
            DateTime.tryParse(map['at']?.toString() ?? '') ?? DateTime.now(),
      );
}
