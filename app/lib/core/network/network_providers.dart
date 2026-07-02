import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/core_providers.dart';
import 'api_client.dart';
import 'auth_token_store.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Assembles and provides the configured [Dio] instance and [ApiClient].
///
/// The Dio instance is built from [AppEnvironment] (base URL, timeouts) and has
/// its interceptor chain wired in a deliberate order: auth first (so retries
/// see fresh tokens), logging last (so it observes the final request/response).
final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvironmentProvider);
  final tokenStore = ref.watch(authTokenStoreProvider);
  final logger = ref.watch(loggerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: env.connectTimeout,
      receiveTimeout: env.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(dio, tokenStore),
  );

  if (env.enableNetworkLogging) {
    dio.interceptors.add(LoggingInterceptor(logger));
  }

  ref.onDispose(dio.close);
  return dio;
});

/// The app's HTTP facade. Datasources depend on this.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
