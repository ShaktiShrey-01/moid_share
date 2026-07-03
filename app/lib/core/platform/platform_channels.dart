/// Central registry of platform-channel identifiers.
///
/// Every MethodChannel/EventChannel name lives here so the Dart side and the
/// native side (Kotlin today, Swift later) reference a single source of truth.
/// Names are namespaced under the app bundle id to avoid collisions.
///
/// ### The seam contract
/// The Dart side calls these channels; the native side registers handlers for
/// them. On Android the handlers are implemented in Kotlin. On macOS they will
/// be implemented in Swift by another engineer — the Dart code does not change.
abstract final class PlatformChannels {
  const PlatformChannels._();

  static const String _base = 'com.moidshare';

  // -- MethodChannels (request/response) -----------------------------------
  /// Clipboard read/write bridge.
  static const String clipboardMethods = '$_base/clipboard/methods';

  /// Device discovery control (start/stop scan, advertise).
  static const String discoveryMethods = '$_base/discovery/methods';

  /// File-transfer control on the native side (accept/reject/receive).
  static const String transferMethods = '$_base/transfer/methods';

  /// Native notifications & foreground-service control (Android now).
  static const String systemMethods = '$_base/system/methods';

  // -- EventChannels (native -> Dart streams) ------------------------------
  /// Emits clipboard-changed events observed natively.
  static const String clipboardEvents = '$_base/clipboard/events';

  /// Emits discovered/lost nearby devices.
  static const String discoveryEvents = '$_base/discovery/events';

  /// Emits transfer progress/lifecycle events.
  static const String transferEvents = '$_base/transfer/events';

  /// Emits files handed to the app via the Android share sheet (ACTION_SEND).
  static const String shareEvents = '$_base/share/events';
}
