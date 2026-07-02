import 'package:flutter/services.dart';

import '../error/exceptions.dart';

/// Reusable, typed wrapper around a [MethodChannel] and optional
/// [EventChannel].
///
/// Every native-facing bridge (clipboard, discovery, transfer) composes a
/// [NativeBridge] rather than talking to `MethodChannel` directly. This gives
/// us one place to:
///   * translate [PlatformException] / [MissingPluginException] into the app's
///     [PlatformChannelException] (the latter is expected on macOS until the
///     Swift side is implemented), and
///   * expose native event streams as broadcast Dart streams.
class NativeBridge {
  NativeBridge({
    required String methodChannel,
    String? eventChannel,
  })  : _methods = MethodChannel(methodChannel),
        _events = eventChannel == null ? null : EventChannel(eventChannel);

  final MethodChannel _methods;
  final EventChannel? _events;

  /// Invokes a native [method], mapping platform errors to app exceptions.
  ///
  /// Returns `null` if the native side returns nothing.
  Future<T?> invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _methods.invokeMethod<T>(method, args);
    } on MissingPluginException catch (e, s) {
      // Native handler not registered — expected on platforms not yet wired.
      throw PlatformChannelException(
        'Native handler for "$method" is not implemented on this platform',
        e,
        s,
      );
    } on PlatformException catch (e, s) {
      throw PlatformChannelException(
        e.message ?? 'Native call "$method" failed',
        e,
        s,
      );
    }
  }

  /// Broadcast stream of native events. Throws [StateError] if this bridge was
  /// constructed without an event channel.
  Stream<dynamic> events([Map<String, dynamic>? arguments]) {
    final channel = _events;
    if (channel == null) {
      throw StateError('This bridge has no event channel configured.');
    }
    return channel.receiveBroadcastStream(arguments);
  }
}
