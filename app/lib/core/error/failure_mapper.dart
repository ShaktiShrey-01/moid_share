import 'exceptions.dart';
import 'failure.dart';

/// Maps a data-layer [AppException] to a domain [Failure].
///
/// This is the single translation point every repository uses, so error
/// handling is consistent app-wide and the UI only ever deals with [Failure].
Failure mapExceptionToFailure(Object error) {
  if (error is AppException) {
    return switch (error) {
      NetworkException() => NetworkFailure(cause: error),
      UnauthorizedException() => AuthFailure(cause: error),
      ValidationException(:final errors, :final message) => ValidationFailure(
          message: message ?? 'Validation failed',
          fieldErrors: errors,
          cause: error,
        ),
      ServerException(:final message, :final statusCode) => ServerFailure(
          message: message ?? 'Server error',
          statusCode: statusCode,
          cause: error,
        ),
      CacheException(:final message) =>
        CacheFailure(message: message ?? 'Storage error', cause: error),
      PlatformChannelException(:final message) =>
        PlatformFailure(message: message ?? 'Platform error', cause: error),
      CancelledException() => CancelledFailure(cause: error),
      UnknownException(:final message) =>
        UnexpectedFailure(message: message ?? 'Unexpected error', cause: error),
    };
  }
  return UnexpectedFailure(cause: error);
}
