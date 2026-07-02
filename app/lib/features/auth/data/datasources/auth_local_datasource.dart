import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/auth_user.dart';
import '../models/auth_user_model.dart';

/// Persists the session locally: **tokens** in secure (keystore) storage and
/// the **user profile** in the (non-sensitive) settings store.
///
/// This is the source of truth the network layer reads the access token from.
class AuthLocalDataSource {
  AuthLocalDataSource({
    required SecureStorage secureStorage,
    required KeyValueStore settingsStore,
  })  : _secure = secureStorage,
        _settings = settingsStore;

  static const String _userKey = 'auth.user';

  final SecureStorage _secure;
  final KeyValueStore _settings;

  Future<void> persistSession(AuthSession session) async {
    await _secure.write(SecureStorageKeys.accessToken, session.tokens.accessToken);
    await _secure.write(SecureStorageKeys.refreshToken, session.tokens.refreshToken);
    await _settings.set(_userKey, jsonEncode(AuthUserModel.toJson(session.user)));
  }

  /// Rehydrates the persisted user + tokens, or `null` if not signed in.
  Future<AuthSession?> restoreSession() async {
    final access = await _secure.read(SecureStorageKeys.accessToken);
    final refresh = await _secure.read(SecureStorageKeys.refreshToken);
    final rawUser = _settings.get<String>(_userKey);
    if (access == null || refresh == null || rawUser == null) return null;

    final user = AuthUserModel.fromJson(
      jsonDecode(rawUser) as Map<String, dynamic>,
    );
    return AuthSession(
      user: user,
      tokens: AuthTokens(accessToken: access, refreshToken: refresh),
    );
  }

  Future<String?> readRefreshToken() =>
      _secure.read(SecureStorageKeys.refreshToken);

  Future<void> cacheUser(AuthUser user) async =>
      _settings.set(_userKey, jsonEncode(AuthUserModel.toJson(user)));

  Future<void> clear() async {
    await _secure.delete(SecureStorageKeys.accessToken);
    await _secure.delete(SecureStorageKeys.refreshToken);
    await _settings.remove(_userKey);
  }
}
