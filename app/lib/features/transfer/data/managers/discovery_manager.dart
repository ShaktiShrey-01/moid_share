import '../../../../core/platform/platform_seams.dart';

/// Finds reachable peers for a direct transfer (the "Discovery Manager").
///
/// It is a thin, testable orchestration layer over the native [DiscoveryBridge]
/// seam (mDNS/Bonjour, Nearby, etc.). Discovery itself is inherently native —
/// Android advertises/browses in Kotlin; macOS will do the same in Swift. This
/// manager exposes that as a plain Dart API so the transfer flow and UI never
/// touch platform channels directly.
class DiscoveryManager {
  DiscoveryManager(this._bridge);

  final DiscoveryBridge _bridge;

  /// Live set of nearby devices, updated as peers appear/disappear.
  Stream<List<DiscoveredDevice>> devices() => _bridge.devices();

  /// Starts advertising this device and browsing for peers.
  Future<void> start({required String displayName}) async {
    await _bridge.startAdvertising(displayName: displayName);
    await _bridge.startBrowsing();
  }

  /// Stops advertising and browsing.
  Future<void> stop() async {
    await _bridge.stopBrowsing();
    await _bridge.stopAdvertising();
  }
}
