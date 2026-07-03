import '../platform/native_bridge.dart';
import '../platform/platform_channels.dart';

/// Shows system notifications and controls the transfer foreground service.
///
/// This is a thin Dart seam over the native `system` channel. Android
/// implements it in Kotlin (notification channels + a foreground `Service`);
/// macOS will implement the same contract in Swift (`UNUserNotificationCenter`)
/// later. Features depend on this interface, never on platform channels.
abstract interface class NotificationService {
  /// Shows or updates a progress notification (e.g. an active transfer).
  ///
  /// [progress]/[max] drive the bar; pass [indeterminate] while the total is
  /// unknown. Reusing the same [id] updates the existing notification in place.
  Future<void> showProgress({
    required int id,
    required String title,
    required String text,
    int progress = 0,
    int max = 100,
    bool indeterminate = false,
  });

  /// Replaces a progress notification with a terminal (completed/failed) one.
  Future<void> complete({
    required int id,
    required String title,
    required String text,
  });

  /// Dismisses the notification with [id].
  Future<void> cancel(int id);

  /// Starts the foreground service that keeps transfers alive in the
  /// background. Safe to call repeatedly.
  Future<void> startTransferService();

  /// Stops the foreground service when no transfers remain active.
  Future<void> stopTransferService();
}

/// MethodChannel implementation over [PlatformChannels.systemMethods].
class MethodChannelNotificationService implements NotificationService {
  MethodChannelNotificationService([NativeBridge? bridge])
      : _bridge = bridge ??
            NativeBridge(methodChannel: PlatformChannels.systemMethods);

  final NativeBridge _bridge;

  @override
  Future<void> showProgress({
    required int id,
    required String title,
    required String text,
    int progress = 0,
    int max = 100,
    bool indeterminate = false,
  }) =>
      _bridge.invoke<void>('showProgress', {
        'id': id,
        'title': title,
        'text': text,
        'progress': progress,
        'max': max,
        'indeterminate': indeterminate,
      });

  @override
  Future<void> complete({
    required int id,
    required String title,
    required String text,
  }) =>
      _bridge.invoke<void>('complete', {'id': id, 'title': title, 'text': text});

  @override
  Future<void> cancel(int id) => _bridge.invoke<void>('cancel', {'id': id});

  @override
  Future<void> startTransferService() =>
      _bridge.invoke<void>('startTransferService');

  @override
  Future<void> stopTransferService() =>
      _bridge.invoke<void>('stopTransferService');
}
