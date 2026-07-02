import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

/// Auth domain contract. Implemented in the data layer; consumed by the
/// presentation controller. All methods return [Result] — never throw.
abstract interface class AuthRepository {
  Future<Result<AuthSession>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  /// Exchanges a Google ID token for a Moid-Share session.
  Future<Result<AuthSession>> googleSignIn({required String idToken});

  /// Fetches the current user using the stored access token.
  Future<Result<AuthUser>> me();

  /// Requests a password-reset email. Always succeeds (no enumeration).
  Future<Result<void>> forgotPassword({required String email});

  /// Completes a password reset using the emailed token.
  Future<Result<void>> resetPassword({
    required String token,
    required String password,
  });

  /// Revokes the current refresh session server-side.
  Future<Result<void>> logout({required String refreshToken});
}
