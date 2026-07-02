import 'dart:async';

/// Lightweight one-way signal used to tell the app the session was invalidated
/// from a low level (e.g. the network layer cleared tokens after a failed
/// refresh). The [AuthController] listens and flips UI state to signed-out.
class SessionEventBus {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSignedOut => _controller.stream;

  void notifySignedOut() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}
