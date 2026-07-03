/// Direction of a transfer relative to this device.
enum TransferDirection { outgoing, incoming }

/// Lifecycle status of a transfer.
///
/// Mirrors the signaling flow: an [offered] transfer is [accepted] (→ [active])
/// or [rejected]; an active transfer ends [completed], [failed] or [cancelled].
enum TransferStatus {
  offered,
  accepted,
  active,
  completed,
  rejected,
  cancelled,
  failed,
}

/// A single file transfer (domain entity).
///
/// Immutable; state changes produce a new instance via [copyWith]. This is what
/// the history UI renders and what the controller advances through the
/// signaling lifecycle. File bytes are never held here — only metadata and
/// progress.
class TransferItem {
  const TransferItem({
    required this.id,
    required this.fileName,
    required this.size,
    required this.direction,
    required this.status,
    required this.createdAt,
    this.contentType = 'application/octet-stream',
    this.peerDeviceId,
    this.bytesTransferred = 0,
    this.error,
  });

  final String id;
  final String fileName;
  final int size;
  final String contentType;
  final TransferDirection direction;
  final TransferStatus status;
  final String? peerDeviceId;
  final int bytesTransferred;
  final String? error;
  final DateTime createdAt;

  /// Fraction complete in `[0, 1]`.
  double get progress => size == 0 ? 0 : (bytesTransferred / size).clamp(0, 1);

  /// True once the transfer has reached a terminal state.
  bool get isTerminal => switch (status) {
        TransferStatus.completed ||
        TransferStatus.rejected ||
        TransferStatus.cancelled ||
        TransferStatus.failed =>
          true,
        _ => false,
      };

  TransferItem copyWith({
    TransferStatus? status,
    int? bytesTransferred,
    String? peerDeviceId,
    String? error,
  }) {
    return TransferItem(
      id: id,
      fileName: fileName,
      size: size,
      contentType: contentType,
      direction: direction,
      status: status ?? this.status,
      peerDeviceId: peerDeviceId ?? this.peerDeviceId,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      error: error ?? this.error,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'size': size,
        'contentType': contentType,
        'direction': direction.name,
        'status': status.name,
        'peerDeviceId': peerDeviceId,
        'bytesTransferred': bytesTransferred,
        'error': error,
        'createdAt': createdAt.toIso8601String(),
      };

  static TransferItem fromJson(Map<String, dynamic> json) => TransferItem(
        id: json['id'] as String,
        fileName: json['fileName'] as String? ?? 'file',
        size: (json['size'] as num?)?.toInt() ?? 0,
        contentType: json['contentType'] as String? ?? 'application/octet-stream',
        direction: TransferDirection.values.firstWhere(
          (d) => d.name == json['direction'],
          orElse: () => TransferDirection.outgoing,
        ),
        status: TransferStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TransferStatus.completed,
        ),
        peerDeviceId: json['peerDeviceId'] as String?,
        bytesTransferred: (json['bytesTransferred'] as num?)?.toInt() ?? 0,
        error: json['error'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
