import 'failure.dart';

/// A functional result type: either a [Success] carrying a value of type [T]
/// or a [ResultFailure] carrying a [Failure].
///
/// We use `Result<T>` instead of throwing across layer boundaries so that the
/// type system forces callers to handle the error case. Repositories return
/// `Future<Result<T>>`; use-cases and providers pattern-match on it.
///
/// ```dart
/// final result = await repo.login(email, password);
/// switch (result) {
///   case Success(:final value):   // use value
///   case ResultFailure(:final failure): // show failure.message
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Wraps a successful [value].
  const factory Result.success(T value) = Success<T>;

  /// Wraps a [failure].
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  /// True when this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// True when this is a [ResultFailure].
  bool get isFailure => this is ResultFailure<T>;

  /// Returns the value if [Success], otherwise `null`.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        ResultFailure<T>() => null,
      };

  /// Returns the failure if [ResultFailure], otherwise `null`.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        ResultFailure<T>(:final failure) => failure,
      };

  /// Folds both branches into a single value of type [R].
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        ResultFailure<T>(:final failure) => onFailure(failure),
      };

  /// Transforms the success value, preserving a failure unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Result<R>.success(transform(value)),
        ResultFailure<T>(:final failure) => Result<R>.failure(failure),
      };

  /// Chains another [Result]-returning operation on success (monadic bind).
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      switch (this) {
        Success<T>(:final value) => transform(value),
        ResultFailure<T>(:final failure) => Result<R>.failure(failure),
      };
}

/// Successful branch of a [Result].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Failed branch of a [Result].
final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is ResultFailure<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}

/// Convenience for `void` results where only success/failure matters.
typedef UnitResult = Result<void>;
