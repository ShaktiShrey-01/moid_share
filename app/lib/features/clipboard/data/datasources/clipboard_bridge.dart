import '../../../../core/platform/native_bridge.dart';
import '../../../../core/platform/platform_channels.dart';
import '../../../../core/platform/platform_seams.dart';

/// Concrete [ClipboardBridge] over the platform channels.
///
/// Android implements the handlers in Kotlin (see MainActivity). macOS will
/// implement the same channels in Swift later. Its distinctive value is the
/// [changes] stream — native clipboard-change monitoring the Dart layer can't
/// do on its own.
class MethodChannelClipboardBridge implements ClipboardBridge {
  MethodChannelClipboardBridge([NativeBridge? bridge])
      : _bridge = bridge ??
            NativeBridge(
              methodChannel: PlatformChannels.clipboardMethods,
              eventChannel: PlatformChannels.clipboardEvents,
            );

  final NativeBridge _bridge;

  @override
  Future<ClipboardPayload?> read() async {
    final res = await _bridge.invoke<Map<dynamic, dynamic>>('read');
    final text = res?['text'] as String?;
    if (text == null) return null;
    return ClipboardPayload(text: text, timestampMs: res?['timestampMs'] as int?);
  }

  @override
  Future<void> write(String text) =>
      _bridge.invoke<void>('write', {'text': text});

  @override
  Stream<ClipboardPayload> changes() => _bridge.events().map((event) {
        final map = event as Map;
        return ClipboardPayload(
          text: map['text'] as String? ?? '',
          timestampMs: map['timestampMs'] as int?,
        );
      });
}
