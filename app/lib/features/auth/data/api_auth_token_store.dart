import 'package:dio/dio.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/auth_token_store.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import 'datasources/auth_local_datasource.dart';
import 'session_event_bus.dart';

/// Real [AuthTokenStore] backing the network layer's auth interceptor.
///
/// Overrides the core default. Uses a **bare** Dio (no interceptors) for the
/// refresh call so it can never recurse through the auth interceptor. On an
/// unrecoverable refresh failure it clears local state and broadcasts a
/// signed-out event so the UI reacts.
class ApiAuthTokenStore implements AuthTokenStore {
  ApiAuthTokenStore({
    required SecureStorage secureStorage,
    required AuthLocalDataSource localDataSource,
    required AppEnvironment env,
    required SessionEventBus eventBus,
    required AppLogger appLogger,
  })  : _secure = secureStorage,
        _local = localDataSource,
        _bus = eventBus,
        _logger = appLogger,
        _dio = Dio(
          BaseOptions(
            baseUrl: env.apiBaseUrl,
            connectTimeout: env.connectTimeout,
            receiveTimeout: env.receiveTimeout,
            headers: const {'Accept': 'application/json'},
          ),
        );

  final SecureStorage _secure;
  final AuthLocalDataSource _local;
  final SessionEventBus _bus;
  final AppLogger _logger;
  final Dio _dio;

  @override
  Future<String?> accessToken() =>
      _secure.read(SecureStorageKeys.accessToken);

  @override
  Future<bool> refreshSession() async {
    final refreshToken = await _secure.read(SecureStorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final tokens = (res.data?['data'] as Map<String, dynamic>?)?['tokens']
          as Map<String, dynamic>?;
      if (tokens == null) return false;

      await _secure.write(
        SecureStorageKeys.accessToken,
        tokens['accessToken'] as String,
      );
      await _secure.write(
        SecureStorageKeys.refreshToken,
        tokens['refreshToken'] as String,
      );
      return true;
    } catch (e) {
      _logger.warn('Token refresh failed', error: e);
      return false;
    }
  }

  @override
  Future<void> clearSession() async {
    await _local.clear();
    _bus.notifySignedOut();
  }
}
