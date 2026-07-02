import 'package:dio/dio.dart';

import 'dio_error_mapper.dart';

/// Thin, testable HTTP facade over [Dio].
///
/// Datasources depend on [ApiClient], never on Dio directly. Every method
/// funnels through [_guard], which converts any [DioException] into an
/// [AppException] via [DioErrorMapper] — so callers only ever handle the app's
/// own exception types.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.get<T>(
            path,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
          ));

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.post<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
          ));

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.put<T>(path, data: data, cancelToken: cancelToken));

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.patch<T>(path, data: data, cancelToken: cancelToken));

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) =>
      _guard(() => _dio.delete<T>(path, data: data, cancelToken: cancelToken));

  /// Runs [request], translating Dio errors into [AppException]s.
  Future<Response<T>> _guard<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw DioErrorMapper.map(e);
    }
  }
}
