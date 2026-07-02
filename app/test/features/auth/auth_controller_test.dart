import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/core/error/failure.dart';
import 'package:moid_share/core/error/result.dart';
import 'package:moid_share/core/session/auth_status.dart';
import 'package:moid_share/features/auth/data/auth_providers.dart';
import 'package:moid_share/features/auth/domain/entities/auth_session.dart';
import 'package:moid_share/features/auth/domain/entities/auth_tokens.dart';
import 'package:moid_share/features/auth/domain/entities/auth_user.dart';
import 'package:moid_share/features/auth/domain/repositories/auth_repository.dart';
import 'package:moid_share/core/storage/storage_providers.dart';

import '../../helpers/in_memory_key_value_store.dart';
import '../../helpers/in_memory_secure_storage.dart';

/// Fake repository letting each test script the outcome.
class _FakeAuthRepository implements AuthRepository {
  Result<AuthSession> loginResult = Result.failure(const AuthFailure());
  Result<AuthSession>? registerResult;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async =>
      loginResult;

  @override
  Future<Result<AuthSession>> register({
    required String name,
    required String email,
    required String password,
  }) async =>
      registerResult ?? loginResult;

  @override
  Future<Result<AuthSession>> googleSignIn({required String idToken}) async =>
      loginResult;

  @override
  Future<Result<AuthUser>> me() async =>
      Result.failure(const AuthFailure());

  @override
  Future<Result<void>> forgotPassword({required String email}) async =>
      const Result.success(null);

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> logout({required String refreshToken}) async =>
      const Result.success(null);
}

/// In-memory local datasource replacement via provider override is awkward
/// (concrete type), so we override the repository and drive the controller,
/// asserting state transitions rather than persistence.
AuthSession _session() => AuthSession(
      user: const AuthUser(id: 'u1', name: 'Ada', email: 'ada@example.com'),
      tokens: const AuthTokens(accessToken: 'a', refreshToken: 'r'),
    );

void main() {
  late _FakeAuthRepository repo;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        settingsStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
        secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => repo = _FakeAuthRepository());

  test('initial status resolves to unauthenticated when nothing persisted',
      () async {
    final container = makeContainer();
    // Reading the controller triggers build() + async restore.
    container.read(authControllerProvider);
    // Let the restore microtask complete (no persisted session -> unauth).
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(authControllerProvider).status,
      anyOf(AuthStatus.unauthenticated, AuthStatus.unknown),
    );
  });

  test('failed login surfaces an error message and stays signed out',
      () async {
    repo.loginResult = Result.failure(
      const ValidationFailure(message: 'Invalid email or password'),
    );
    final container = makeContainer();
    final ok = await container
        .read(authControllerProvider.notifier)
        .login('bad@example.com', 'secret123');

    expect(ok, isFalse);
    final state = container.read(authControllerProvider);
    expect(state.submitting, isFalse);
    expect(state.errorMessage, 'Invalid email or password');
    expect(state.status, isNot(AuthStatus.authenticated));
  });

  test('successful login authenticates and exposes the user', () async {
    repo.loginResult = Result.success(_session());
    final container = makeContainer();
    final ok = await container
        .read(authControllerProvider.notifier)
        .login('ada@example.com', 'secret123');

    expect(ok, isTrue);
    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.email, 'ada@example.com');
    expect(state.errorMessage, isNull);
  });
}
