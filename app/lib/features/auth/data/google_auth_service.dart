import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/error/exceptions.dart';

/// Obtains a Google **ID token** to exchange with the backend `/auth/google`.
///
/// Abstracted so the controller depends on an interface (testable/mable) and
/// so the concrete `google_sign_in` usage lives in one place.
abstract interface class GoogleAuthService {
  /// Whether a server client id is configured for this build.
  bool get isConfigured;

  /// Runs the native Google Sign-In flow and returns an ID token.
  ///
  /// Throws [CancelledException] if the user aborts, or
  /// [PlatformChannelException] if unconfigured/unsupported/failed.
  Future<String> obtainIdToken();
}

/// [GoogleAuthService] backed by the `google_sign_in` v7 API.
class GoogleSignInService implements GoogleAuthService {
  GoogleSignInService(this._serverClientId);

  final String _serverClientId;
  bool _initialized = false;

  @override
  bool get isConfigured => _serverClientId.isNotEmpty;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  @override
  Future<String> obtainIdToken() async {
    if (!isConfigured) {
      throw const PlatformChannelException(
        'Google sign-in is not configured on this build',
      );
    }

    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw const PlatformChannelException(
        'Google sign-in is not supported on this platform',
      );
    }

    await _ensureInitialized();

    try {
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const PlatformChannelException('Google did not return an ID token');
      }
      return idToken;
    } on GoogleSignInException catch (e, s) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw CancelledException('Google sign-in cancelled', e, s);
      }
      throw PlatformChannelException(
        e.description ?? 'Google sign-in failed',
        e,
        s,
      );
    }
  }
}
