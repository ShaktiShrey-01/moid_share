import 'package:flutter/services.dart';

import '../../../core/platform/platform_seams.dart';

/// Reads/writes the **system clipboard** and exposes native change events.
///
/// Read/write use Flutter's built-in clipboard API (reliable on every
/// platform). The change *stream* comes from the native [ClipboardBridge]
/// (auto-capture), which the framework cannot provide.
class ClipboardService {
  ClipboardService(this._bridge);

  final ClipboardBridge _bridge;

  Future<String?> read() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  Future<void> write(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Native clipboard-change events. May error on platforms without a native
  /// implementation — callers should guard the subscription.
  Stream<ClipboardPayload> systemChanges() => _bridge.changes();
}
