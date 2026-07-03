import '../../../../core/platform/native_bridge.dart';
import '../../../../core/platform/platform_channels.dart';
import '../../../../core/platform/platform_seams.dart';

/// Streams files the OS hands the app through the share sheet.
///
/// On Android these arrive via `ACTION_SEND` / `ACTION_SEND_MULTIPLE`; the
/// native side resolves each to a readable `content://` URI and emits it here.
/// macOS will feed its Services / drag-drop entry points into the same contract
/// later. The emitted [PickedFile] is identical to a picker result, so shared
/// files flow through the exact same offer path.
abstract interface class ShareBridge {
  /// Files shared into the app, one event per file (replays the launch file
  /// to the first subscriber).
  Stream<PickedFile> sharedFiles();
}

/// EventChannel implementation over [PlatformChannels.shareEvents].
class MethodChannelShareBridge implements ShareBridge {
  MethodChannelShareBridge([NativeBridge? bridge])
      : _bridge = bridge ??
            NativeBridge(
              methodChannel: PlatformChannels.transferMethods,
              eventChannel: PlatformChannels.shareEvents,
            );

  final NativeBridge _bridge;

  @override
  Stream<PickedFile> sharedFiles() => _bridge.events().map((event) {
        final map = Map<String, dynamic>.from(event as Map);
        return PickedFile(
          id: map['id'] as String? ?? '',
          name: map['name'] as String? ?? 'file',
          size: (map['size'] as num?)?.toInt() ?? 0,
          contentType:
              map['contentType'] as String? ?? 'application/octet-stream',
        );
      });
}
