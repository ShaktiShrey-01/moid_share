import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/core/error/failure.dart';
import 'package:moid_share/core/error/result.dart';

void main() {
  group('Result', () {
    test('Success exposes value and folds to the success branch', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
      expect(result.fold((v) => 'ok:$v', (f) => 'err'), 'ok:42');
    });

    test('ResultFailure exposes failure and folds to the failure branch', () {
      const failure = NetworkFailure();
      const result = Result<int>.failure(failure);

      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, same(failure));
      expect(result.fold((v) => 'ok', (f) => 'err:${f.code}'), 'err:network');
    });

    test('map transforms success and preserves failure', () {
      expect(const Result<int>.success(2).map((v) => v * 10).valueOrNull, 20);

      const failing = Result<int>.failure(CacheFailure());
      expect(failing.map((v) => v * 10).failureOrNull, isA<CacheFailure>());
    });

    test('flatMap chains on success and short-circuits on failure', () {
      Result<String> stringify(int v) => Result.success('#$v');

      expect(const Result<int>.success(7).flatMap(stringify).valueOrNull, '#7');

      const failing = Result<int>.failure(AuthFailure());
      expect(failing.flatMap(stringify).failureOrNull, isA<AuthFailure>());
    });

    test('value equality holds for identical branches', () {
      expect(const Success(1), const Success(1));
      expect(
        const ResultFailure<int>(NetworkFailure()),
        const ResultFailure<int>(NetworkFailure()),
      );
    });
  });
}
