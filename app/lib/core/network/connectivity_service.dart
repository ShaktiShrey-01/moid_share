import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive network-reachability signal used for offline handling.
///
/// Wraps `connectivity_plus` behind a boolean API. Note: this reports whether a
/// network interface is available, not whether our server is reachable — treat
/// it as a fast-path hint, with actual request failures as the source of truth.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits `true` when at least one non-`none` interface is present.
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  /// One-shot connectivity check.
  Future<bool> isOnline() async =>
      _isOnline(await _connectivity.checkConnectivity());

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

/// Singleton [ConnectivityService].
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Streams the current online/offline state for the UI (banners, retry logic).
final connectivityStatusProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onStatusChange,
);
