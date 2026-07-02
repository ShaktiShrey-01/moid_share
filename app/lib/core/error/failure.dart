/// Domain-level, user-facing error values.
///
/// A [Failure] is a *value* returned inside a [Result], never thrown. Every
/// [Failure] carries a [message] safe to surface in the UI and a stable
/// [code] the presentation layer can switch on for localization or retry UX.
library;

/// Base type for all recoverable errors that reach the domain/presentation
/// layers. Sealed so `switch` statements are exhaustive.
sealed class Failure {
  const Failure({required this.message, this.code, this.cause});

  /// Human-readable, UI-safe description (already sanitized — no stack traces,
  /// no server internals).
  final String message;

  /// Stable machine code for programmatic handling / localization keys.
  final String? code;

  /// The underlying error, kept for logging only. Never shown to users.
  final Object? cause;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Server responded with an error status. [statusCode] is the HTTP code.
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code,
    super.cause,
  });

  final int? statusCode;
}

/// No/blocked connectivity or a timeout — typically retryable.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'network',
    super.cause,
  });
}

/// Authentication/authorization failed; the UI should send the user to login.
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Your session has expired. Please sign in again.',
    super.code = 'unauthorized',
    super.cause,
  });
}

/// Server-side form validation errors, keyed by field.
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
    super.code = 'validation',
    super.cause,
  });

  final Map<String, List<String>> fieldErrors;
}

/// Local cache/persistence error.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Could not access local storage.',
    super.code = 'cache',
    super.cause,
  });
}

/// A platform-channel/native error (e.g. macOS side not yet implemented).
class PlatformFailure extends Failure {
  const PlatformFailure({
    required super.message,
    super.code = 'platform',
    super.cause,
  });
}

/// The operation was cancelled intentionally.
class CancelledFailure extends Failure {
  const CancelledFailure({
    super.message = 'Operation cancelled.',
    super.code = 'cancelled',
    super.cause,
  });
}

/// Unexpected/uncategorized error.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Something went wrong. Please try again.',
    super.code = 'unexpected',
    super.cause,
  });
}
