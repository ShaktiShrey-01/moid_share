import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_environment.dart';
import '../logging/app_logger.dart';
import '../network/auth_token_store.dart';

/// Generic authenticated realtime transport over Socket.IO.
///
/// Deliberately feature-agnostic: it knows nothing about clipboard/devices. It
/// exposes per-event broadcast streams and an ack-based emit, so features
/// compose their own protocols on top (e.g. the clipboard feature listens on
/// `clipboard:incoming` and emits `clipboard:sync`).
///
/// The access token is read from [AuthTokenStore] at connect time; the caller
/// supplies the stable device id (owned by the devices feature) to keep this in
/// the core layer with no upward dependency.
class SocketManager {
  SocketManager({
    required AppEnvironment environment,
    required AuthTokenStore authTokenStore,
    required AppLogger appLogger,
  })  : _env = environment,
        _tokenStore = authTokenStore,
        _logger = appLogger;

  final AppEnvironment _env;
  final AuthTokenStore _tokenStore;
  final AppLogger _logger;

  io.Socket? _socket;
  final Map<String, StreamController<dynamic>> _eventControllers = {};
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Emits `true` on connect and `false` on disconnect.
  Stream<bool> get connectionState => _connectionController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Broadcast stream of payloads for a named server event.
  Stream<dynamic> on(String event) =>
      _eventControllers.putIfAbsent(event, () {
        final controller = StreamController<dynamic>.broadcast();
        _socket?.on(event, controller.add);
        return controller;
      }).stream;

  /// Connects (idempotent) using the stored access token + [deviceId].
  Future<void> connect({required String deviceId}) async {
    if (_socket != null) return;

    final token = await _tokenStore.accessToken();
    if (token == null || token.isEmpty) {
      _logger.warn('[socket] connect skipped: no access token');
      return;
    }

    final socket = io.io(
      _env.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token, 'deviceId': deviceId})
          .build(),
    );

    socket
      ..onConnect((_) {
        _logger.info('[socket] connected');
        _connectionController.add(true);
      })
      ..onDisconnect((_) {
        _logger.info('[socket] disconnected');
        _connectionController.add(false);
      })
      ..onConnectError((e) => _logger.warn('[socket] connect error', error: e));

    // Re-bind any event listeners registered before connecting.
    for (final entry in _eventControllers.entries) {
      socket.on(entry.key, entry.value.add);
    }

    _socket = socket;
    socket.connect();
  }

  /// Emits [event] with [data] and awaits the server ack (or times out).
  /// Returns the ack map, or `null` on failure/timeout.
  Future<Map<String, dynamic>?> emitWithAck(
    String event,
    dynamic data, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = _socket;
    if (socket == null || !socket.connected) return null;
    try {
      final result =
          await socket.emitWithAckAsync(event, data).timeout(timeout);
      return result is Map ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      _logger.warn('[socket] emit "$event" failed', error: e);
      return null;
    }
  }

  /// Fire-and-forget emit.
  void emit(String event, dynamic data) => _socket?.emit(event, data);

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    for (final c in _eventControllers.values) {
      c.close();
    }
    _eventControllers.clear();
    _connectionController.close();
  }
}
