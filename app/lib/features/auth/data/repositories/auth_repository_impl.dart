import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// [AuthRepository] implementation.
///
/// Sole responsibility: call the remote datasource and translate any thrown
/// [AppException] into a [Failure] via [mapExceptionToFailure], returning a
/// [Result]. Persistence is handled by the controller/local datasource so this
/// stays a thin, pure boundary.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AuthSession>> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _guard(() => _remote.register(name: name, email: email, password: password));

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) =>
      _guard(() => _remote.login(email: email, password: password));

  @override
  Future<Result<AuthSession>> googleSignIn({required String idToken}) =>
      _guard(() => _remote.googleSignIn(idToken: idToken));

  @override
  Future<Result<AuthUser>> me() => _guard(_remote.me);

  @override
  Future<Result<void>> forgotPassword({required String email}) =>
      _guard(() => _remote.forgotPassword(email: email));

  @override
  Future<Result<void>> logout({required String refreshToken}) =>
      _guard(() => _remote.logout(refreshToken: refreshToken));
}
