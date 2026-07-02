import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_providers.dart';

/// Session token seam used by the network layer.
///
/// The [AuthInterceptor] depends on this interface, NOT on the auth feature,
/// so `core/network` has no upward dependency on `features/auth`. The auth
/// feature provides a richer implementation (real refresh call) by overriding
/// [authTokenStoreProvider] once it is built.
abstract interface class AuthTokenStore {
  /// Current access token, or `null` if signed out.
  Future<String?> accessToken();

  /// Attempts to refresh the session using the stored refresh token.
  /// Returns `true` if a new access token is now available.
  Future<bool> refreshSession();

  /// Clears all session tokens (sign-out / unrecoverable 401).
  Future<void> clearSession();
}

/// Default token store: reads/writes the secure storage directly and treats
/// refresh as unavailable. Replaced by the auth feature's implementation,
/// which performs the actual `/auth/refresh` network call.
class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<String?> accessToken() =>
      _secureStorage.read(SecureStorageKeys.accessToken);

  @override
  Future<bool> refreshSession() async => false; // no-op until auth wires it

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(SecureStorageKeys.accessToken);
    await _secureStorage.delete(SecureStorageKeys.refreshToken);
  }
}

/// Provides the active [AuthTokenStore]. Overridden by the auth feature.
final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => SecureAuthTokenStore(ref.watch(secureStorageProvider)),
);
