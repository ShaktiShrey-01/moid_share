import 'dart:typed_data';

/// Abstracts the **direct byte channel** between two devices (the "Connection
/// Manager"). File bytes flow here, never through the backend.
///
/// Implementations vary by transport — a LAN TCP socket, a relay fallback, or a
/// future WebRTC data channel. The rest of the transfer feature depends only on
/// this interface, so swapping transports (or plugging in the macOS side) needs
/// no changes upstream.
abstract interface class ConnectionManager {
  /// Opens a channel to a peer using an opaque [descriptor] negotiated over
  /// signaling (address/port, SDP, …).
  Future<void> open(String descriptor);

  /// Sends one already-encrypted [chunk] to the peer.
  Future<void> send(Uint8List chunk);

  /// Closes the channel.
  Future<void> close();

  /// True while the channel is usable.
  bool get isOpen;
}

/// Placeholder transport used until the native LAN socket is wired.
///
/// It implements the contract so the sender pipeline (pick → encrypt → send)
/// is fully exercisable in tests and the app runs end-to-end in signaling-only
/// mode. Actual on-wire bytes are a documented native seam: the Kotlin side
/// (and later Swift) provides the real socket. Calling [send] before a real
/// transport is installed throws, making the missing seam explicit rather than
/// silently dropping data.
class UnconnectedConnectionManager implements ConnectionManager {
  bool _open = false;

  @override
  bool get isOpen => _open;

  @override
  Future<void> open(String descriptor) async => _open = true;

  @override
  Future<void> send(Uint8List chunk) async {
    if (!_open) {
      throw StateError('Connection is not open');
    }
    throw UnimplementedError(
      'Direct byte transport is a native seam not yet installed on this '
      'platform. Signaling works; wire the LAN socket in Kotlin/Swift to send.',
    );
  }

  @override
  Future<void> close() async => _open = false;
}
