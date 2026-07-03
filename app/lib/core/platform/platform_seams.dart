/// Abstract platform seams — the contracts the **native** side implements.
///
/// These interfaces are the boundary between shared Dart logic and
/// platform-specific native code:
///   * **Android (now):** implemented in Kotlin via the channels in
///     [PlatformChannels], backed by [NativeBridge].
///   * **macOS (later):** a Swift engineer implements the same channel
///     contracts. No Dart code changes — only a new native handler is added.
///
/// Keeping the contracts here (pure Dart, no Flutter widgets, no platform
/// imports) is what makes the codebase portable and future-proof for Xcode.
library;

/// A single clipboard payload. Kept minimal and platform-neutral.
class ClipboardPayload {
  const ClipboardPayload({required this.text, this.timestampMs});

  final String text;
  final int? timestampMs;
}

/// Native clipboard access seam.
///
/// Android reads/writes the system clipboard via Kotlin; macOS will implement
/// the same contract in Swift (NSPasteboard) later.
abstract interface class ClipboardBridge {
  /// Reads the current clipboard text, or `null` if empty/unsupported.
  Future<ClipboardPayload?> read();

  /// Writes [text] to the system clipboard.
  Future<void> write(String text);

  /// Emits whenever the native clipboard content changes.
  Stream<ClipboardPayload> changes();
}

/// A device discovered on the local network / nearby.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
  });

  final String id;
  final String name;
  final String host;
  final int port;
}

/// Native device-discovery seam (mDNS/Bonjour, Nearby, etc.).
///
/// Android advertises/browses via Kotlin; macOS will implement via Swift
/// (NetService/Network.framework) later.
abstract interface class DiscoveryBridge {
  Future<void> startAdvertising({required String displayName});
  Future<void> stopAdvertising();
  Future<void> startBrowsing();
  Future<void> stopBrowsing();

  /// Emits the current set of reachable devices as it changes.
  Stream<List<DiscoveredDevice>> devices();
}

/// Lifecycle phases of a native-side receive operation.
enum TransferPhase { pending, active, completed, failed, cancelled }

/// Progress snapshot for an in-flight transfer.
class TransferProgress {
  const TransferProgress({
    required this.transferId,
    required this.phase,
    required this.bytesTransferred,
    required this.totalBytes,
  });

  final String transferId;
  final TransferPhase phase;
  final int bytesTransferred;
  final int totalBytes;

  double get fraction => totalBytes == 0 ? 0 : bytesTransferred / totalBytes;
}

/// Native file-receive seam.
///
/// The **sending** side is implemented in Dart (see the transfer feature). The
/// **receiving** side is native: Android receives via Kotlin; macOS will
/// receive via Swift later. This interface is that receiver contract.
abstract interface class TransferReceiverBridge {
  /// Accepts an incoming transfer identified by [transferId].
  Future<void> accept(String transferId, {required String saveToPath});

  /// Rejects an incoming transfer.
  Future<void> reject(String transferId);

  /// Cancels an in-flight transfer.
  Future<void> cancel(String transferId);

  /// Emits progress/lifecycle events for all active transfers.
  Stream<TransferProgress> progress();
}

/// A file the user selected to send, described platform-neutrally.
///
/// [id] is an opaque native handle (an Android `content://` URI, a macOS
/// security-scoped bookmark, etc.) — never assume it is a filesystem path.
/// Bytes are read back through [TransferSenderBridge.openRead].
class PickedFile {
  const PickedFile({
    required this.id,
    required this.name,
    required this.size,
    this.contentType = 'application/octet-stream',
  });

  final String id;
  final String name;
  final int size;
  final String contentType;
}

/// Native file-access seam for the **sending** side.
///
/// Picking a file and streaming its bytes must go through the platform: on
/// Android a chosen file is a `content://` URI (no real path), so only native
/// code can open and read it. Android implements this in Kotlin; macOS will
/// implement the same contract in Swift (`NSOpenPanel` + bookmarks) later.
abstract interface class TransferSenderBridge {
  /// Opens the native file picker. Returns `null` if the user cancels.
  Future<PickedFile?> pickFile();

  /// Streams the bytes of a previously [pickFile]ed file in [chunkSize] blocks.
  Stream<List<int>> openRead(String fileId, {int chunkSize});
}
