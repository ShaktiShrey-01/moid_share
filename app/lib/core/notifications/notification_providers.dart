import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// DI for notifications. Override in tests with a fake service.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => MethodChannelNotificationService(),
);
