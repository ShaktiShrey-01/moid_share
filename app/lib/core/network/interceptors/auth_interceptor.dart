import 'package:dio/dio.dart';

import '../auth_token_store.dart';

/// Attaches the bearer token to outgoing requests and transparently refreshes
/// the session once on a 401 before retrying the original request.
///
/// Single responsibility: authentication concerns only. It holds a reference to
/// the [Dio] used to replay the failed request and to the [AuthTokenStore] seam
/// for tokens/refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, this._tokenStore);

  final Dio _dio;
  final AuthTokenStore _tokenStore;

  /// Requests that must never carry a token (avoids sending a stale token to
  /// the auth endpoints and prevents refresh recursion).
  static const _skipAuthPaths = <String>{
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/google',
  };

  bool _shouldSkip(RequestOptions options) =>
      _skipAuthPaths.any((p) => options.path.contains(p));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldSkip(options)) {
      final token = await _tokenStore.accessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['__retried__'] == true;

    if (!is401 || alreadyRetried || _shouldSkip(err.requestOptions)) {
      return handler.next(err);
    }

    final refreshed = await _tokenStore.refreshSession();
    if (!refreshed) {
      await _tokenStore.clearSession();
      return handler.next(err);
    }

    // Replay the original request once with the fresh token.
    try {
      final token = await _tokenStore.accessToken();
      final options = err.requestOptions
        ..extra['__retried__'] = true
        ..headers['Authorization'] = 'Bearer $token';

      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
