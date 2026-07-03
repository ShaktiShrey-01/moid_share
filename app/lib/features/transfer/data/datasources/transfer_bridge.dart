import '../../../../core/platform/native_bridge.dart';
import '../../../../core/platform/platform_channels.dart';
import '../../../../core/platform/platform_seams.dart';

/// Concrete [TransferSenderBridge] over the platform channels.
///
/// Android implements the handlers in Kotlin (see MainActivity); macOS will
/// implement the same channels in Swift later. File picking and byte reads are
/// native because a chosen file on Android is a `content://` URI with no path.
class MethodChannelTransferSenderBridge implements TransferSenderBridge {
  MethodChannelTransferSenderBridge([NativeBridge? bridge])
      : _bridge = bridge ??
            NativeBridge(methodChannel: PlatformChannels.transferMethods);

  final NativeBridge _bridge;

  @override
  Future<PickedFile?> pickFile() async {
    final res = await _bridge.invoke<Map<dynamic, dynamic>>('pickFile');
    if (res == null) return null;
    final id = res['id'] as String?;
    if (id == null) return null;
    return PickedFile(
      id: id,
      name: res['name'] as String? ?? 'file',
      size: (res['size'] as num?)?.toInt() ?? 0,
      contentType: res['contentType'] as String? ?? 'application/octet-stream',
    );
  }

  @override
  Stream<List<int>> openRead(String fileId, {int chunkSize = 64 * 1024}) async* {
    var offset = 0;
    while (true) {
      final bytes = await _bridge.invoke<List<int>>('readChunk', {
        'id': fileId,
        'offset': offset,
        'length': chunkSize,
      });
      if (bytes == null || bytes.isEmpty) break;
      yield bytes;
      offset += bytes.length;
      if (bytes.length < chunkSize) break;
    }
  }
}

/// Concrete [TransferReceiverBridge] over the platform channels.
///
/// The receiving side is native (Android SAF / macOS save panel). This bridge
/// forwards accept/reject/cancel and surfaces native progress events.
class MethodChannelTransferReceiverBridge implements TransferReceiverBridge {
  MethodChannelTransferReceiverBridge([NativeBridge? bridge])
      : _bridge = bridge ??
            NativeBridge(
              methodChannel: PlatformChannels.transferMethods,
              eventChannel: PlatformChannels.transferEvents,
            );

  final NativeBridge _bridge;

  @override
  Future<void> accept(String transferId, {required String saveToPath}) =>
      _bridge.invoke<void>('acceptReceive', {
        'transferId': transferId,
        'saveToPath': saveToPath,
      });

  @override
  Future<void> reject(String transferId) =>
      _bridge.invoke<void>('rejectReceive', {'transferId': transferId});

  @override
  Future<void> cancel(String transferId) =>
      _bridge.invoke<void>('cancelReceive', {'transferId': transferId});

  @override
  Stream<TransferProgress> progress() => _bridge.events().map((event) {
        final map = Map<String, dynamic>.from(event as Map);
        return TransferProgress(
          transferId: map['transferId'] as String? ?? '',
          phase: TransferPhase.values.firstWhere(
            (p) => p.name == map['phase'],
            orElse: () => TransferPhase.active,
          ),
          bytesTransferred: (map['bytesTransferred'] as num?)?.toInt() ?? 0,
          totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
        );
      });
}
