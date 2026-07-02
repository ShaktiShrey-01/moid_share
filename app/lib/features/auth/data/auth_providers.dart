import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../../../core/network/auth_token_store.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/repositories/auth_repository.dart';
import '../presentation/controllers/auth_controller.dart';
import '../presentation/controllers/auth_state.dart';
import 'api_auth_token_store.dart';
import 'datasources/auth_local_datasource.dart';
import 'datasources/auth_remote_datasource.dart';
import 'repositories/auth_repository_impl.dart';
import 'session_event_bus.dart';

/// Dependency injection for the auth feature.
///
/// These providers compose the feature and, via bootstrap overrides, plug the
/// real implementations into the core seams (`authTokenStoreProvider`,
/// `authStatusProvider`).

/// Broadcasts low-level session invalidation to the controller.
final sessionEventBusProvider = Provider<SessionEventBus>((ref) {
  final bus = SessionEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(apiClientProvider)),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(
    secureStorage: ref.watch(secureStorageProvider),
    settingsStore: ref.watch(settingsStoreProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

/// The concrete [AuthTokenStore] for the network layer. Bootstrap overrides the
/// core `authTokenStoreProvider` to resolve to this.
final apiAuthTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => ApiAuthTokenStore(
    secureStorage: ref.watch(secureStorageProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    env: ref.watch(appEnvironmentProvider),
    eventBus: ref.watch(sessionEventBusProvider),
    appLogger: ref.watch(loggerProvider),
  ),
);

/// Session + auth-form state. Drives the router guard via the status projection.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
