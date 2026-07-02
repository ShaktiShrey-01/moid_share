import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

/// Logs HTTP traffic through the app's [AppLogger].
///
/// Only installed when `AppEnvironment.enableNetworkLogging` is true (i.e.
/// never in production). It redacts the Authorization header so tokens never
/// reach device logs.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _logger.debug(
      '--> ${options.method} ${options.uri}\n'
      'headers: ${_redact(options.headers)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug(
      '<-- ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.warn(
      'x-- ${err.response?.statusCode ?? '-'} '
      '${err.requestOptions.uri} (${err.type.name})',
      error: err.error,
    );
    handler.next(err);
  }

  Map<String, dynamic> _redact(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) {
      copy['Authorization'] = '***redacted***';
    }
    return copy;
  }
}
