/// Low-level exceptions thrown by the **data layer** (datasources).
///
/// These are intentionally distinct from [Failure]s: exceptions are *thrown*
/// close to the source of an error (a Dio call, a Hive read, a platform
/// channel), while [Failure]s are *returned* values that travel up through the
/// domain layer. Repositories are the boundary that catches these exceptions
/// and maps them to [Failure]s, so the rest of the app never uses try/catch.
library;

/// Base class for every exception originating inside Moid-Share.
///
/// Carries an optional human-readable [message] and the original [cause] so we
/// never lose the root error when translating to a [Failure].
sealed class AppException implements Exception {
  const AppException([this.message, this.cause, this.stackTrace]);

  final String? message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType(${message ?? 'no message'})';
}

/// A request reached the server but it responded with a non-2xx status.
class ServerException extends AppException {
  const ServerException({
    this.statusCode,
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  /// HTTP status code, when available.
  final int? statusCode;
}

/// The request never completed: no connectivity, DNS failure, TLS error, or
/// a connect/receive/send timeout.
class NetworkException extends AppException {
  const NetworkException([super.message, super.cause, super.stackTrace]);
}

/// The server rejected our credentials (401) or the session expired and could
/// not be refreshed. Callers should route the user back to sign-in.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message, super.cause, super.stackTrace]);
}

/// Server-side validation failed (422). [errors] maps field name -> messages.
class ValidationException extends AppException {
  const ValidationException({
    this.errors = const {},
    String? message,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  final Map<String, List<String>> errors;
}

/// A local persistence operation failed (Hive / secure storage).
class CacheException extends AppException {
  const CacheException([super.message, super.cause, super.stackTrace]);
}

/// A platform channel call failed or the native side is not yet implemented
/// (expected on macOS until the Swift engineer wires it up).
class PlatformChannelException extends AppException {
  const PlatformChannelException([super.message, super.cause, super.stackTrace]);
}

/// The operation was cancelled by the caller (e.g. a cancelled transfer).
class CancelledException extends AppException {
  const CancelledException([super.message, super.cause, super.stackTrace]);
}

/// Fallback for anything we did not anticipate. Should be rare; investigate
/// any occurrence in telemetry.
class UnknownException extends AppException {
  const UnknownException([super.message, super.cause, super.stackTrace]);
}
