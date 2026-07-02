import '../../../../core/network/api_client.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../models/auth_tokens_model.dart';
import '../models/auth_user_model.dart';

/// Talks to the backend auth endpoints via [ApiClient].
///
/// Returns parsed domain entities and lets [ApiClient]'s thrown [AppException]s
/// propagate — the repository is responsible for converting them to failures.
/// Paths are relative to the configured API base (which already includes
/// `/api/v1`).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api);

  final ApiClient _api;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return _parseSession(res.data);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseSession(res.data);
  }

  Future<AuthSession> googleSignIn({required String idToken}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'idToken': idToken},
    );
    return _parseSession(res.data);
  }

  Future<AuthUser> me() async {
    final res = await _api.get<Map<String, dynamic>>('/auth/me');
    final data = _data(res.data);
    return AuthUserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> forgotPassword({required String email}) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/reset-password',
      data: {'token': token, 'password': password},
    );
  }

  Future<void> logout({required String refreshToken}) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  // -- helpers -------------------------------------------------------------

  /// Unwraps the standard `{ success, data }` envelope.
  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Malformed response: missing "data"');
  }

  AuthSession _parseSession(Map<String, dynamic>? body) {
    final data = _data(body);
    return AuthSession(
      user: AuthUserModel.fromJson(data['user'] as Map<String, dynamic>),
      tokens: AuthTokensModel.fromJson(data['tokens'] as Map<String, dynamic>),
    );
  }
}
