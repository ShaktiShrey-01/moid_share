import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Translates low-level [DioException]s into the app's [AppException] taxonomy.
///
/// Centralizing this mapping means datasources never inspect Dio types; they
/// simply `catch (AppException)`. Repositories then map [AppException] to a
/// [Failure]. One direction, one place.
abstract final class DioErrorMapper {
  const DioErrorMapper._();

  static AppException map(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode;

    switch (e.type) {
      case DioExceptionType.cancel:
        return CancelledException('Request cancelled', e, e.stackTrace);

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          'Connection problem. Check your network and try again.',
          e,
          e.stackTrace,
        );

      case DioExceptionType.badCertificate:
        return NetworkException('Secure connection failed.', e, e.stackTrace);

      case DioExceptionType.badResponse:
        return _mapStatus(statusCode, response, e);

      case DioExceptionType.unknown:
        return UnknownException(e.message ?? 'Unknown network error', e,
            e.stackTrace);
    }
  }

  static AppException _mapStatus(
    int? statusCode,
    Response<dynamic>? response,
    DioException e,
  ) {
    final serverMessage = _extractMessage(response?.data);

    if (statusCode == 401) {
      return UnauthorizedException(serverMessage ?? 'Unauthorized', e);
    }
    if (statusCode == 422) {
      return ValidationException(
        errors: _extractFieldErrors(response?.data),
        message: serverMessage ?? 'Validation failed',
        cause: e,
      );
    }
    return ServerException(
      statusCode: statusCode,
      message: serverMessage ?? 'Server error ($statusCode)',
      cause: e,
      stackTrace: e.stackTrace,
    );
  }

  /// Extracts a `{ "message": "..." }` field if the backend sent one.
  static String? _extractMessage(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }

  /// Extracts express-validator style `{ "errors": { field: [msg] } }`.
  static Map<String, List<String>> _extractFieldErrors(dynamic data) {
    if (data is Map && data['errors'] is Map) {
      final raw = data['errors'] as Map;
      return raw.map(
        (key, value) => MapEntry(
          key.toString(),
          (value is List)
              ? value.map((v) => v.toString()).toList()
              : <String>[value.toString()],
        ),
      );
    }
    return const {};
  }
}
