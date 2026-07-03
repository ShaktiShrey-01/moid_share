import '../entities/clipboard_entry.dart';

/// Clipboard sync + history contract.
///
/// Combines three concerns behind one interface: the realtime channel (push /
/// incoming), local history persistence, and access to the system clipboard
/// via the platform bridge.
abstract interface class ClipboardRepository {
  /// Stream of clipboard items pushed from the user's other devices.
  Stream<ClipboardEntry> incoming();

  /// Sends [content] to the user's other devices. Returns true on ack.
  Future<bool> push(String content, {String contentType});

  /// Reads the current system clipboard text (via the platform bridge).
  Future<String?> readSystemClipboard();

  /// Writes [content] to the system clipboard (via the platform bridge).
  Future<void> writeSystemClipboard(String content);

  /// Locally-persisted history (most recent first).
  Future<List<ClipboardEntry>> history();
  Future<void> addToHistory(ClipboardEntry entry);
  Future<void> clearHistory();
}
