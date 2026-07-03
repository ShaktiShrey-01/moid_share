import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/core_providers.dart';
import '../network/auth_token_store.dart';
import 'socket_manager.dart';

/// Singleton realtime transport. Features obtain it to build their own
/// event protocols. Disposed with the container.
final socketManagerProvider = Provider<SocketManager>((ref) {
  final manager = SocketManager(
    environment: ref.watch(appEnvironmentProvider),
    authTokenStore: ref.watch(authTokenStoreProvider),
    appLogger: ref.watch(loggerProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});
