import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/session/auth_status.dart';
import '../../domain/entities/auth_session.dart';
import '../../data/auth_providers.dart';
import 'auth_state.dart';

/// Owns session lifecycle and auth-form state.
///
/// The coarse [AuthState.status] is projected onto the core `authStatusProvider`
/// (see bootstrap overrides), so the router reacts to sign-in/out automatically
/// — screens never navigate manually.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // React to low-level session invalidation (failed token refresh).
    final bus = ref.watch(sessionEventBusProvider);
    final sub = bus.onSignedOut.listen((_) => _onSignedOut());
    ref.onDispose(sub.cancel);

    // Optimistically restore any persisted session on startup.
    Future.microtask(_restore);
    return const AuthState();
  }

  Future<void> _restore() async {
    final session = await ref.read(authLocalDataSourceProvider).restoreSession();
    if (!ref.mounted) return;
    state = session == null
        ? state.copyWith(status: AuthStatus.unauthenticated)
        : state.copyWith(status: AuthStatus.authenticated, user: session.user);
  }

  void _onSignedOut() {
    state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
  }

  Future<bool> login(String email, String password) => _authenticate(
        () => ref.read(authRepositoryProvider).login(
              email: email,
              password: password,
            ),
      );

  Future<bool> register(String name, String email, String password) =>
      _authenticate(
        () => ref.read(authRepositoryProvider).register(
              name: name,
              email: email,
              password: password,
            ),
      );

  Future<bool> googleSignIn(String idToken) => _authenticate(
        () => ref.read(authRepositoryProvider).googleSignIn(idToken: idToken),
      );

  /// Runs the native Google flow, then exchanges the ID token for a session.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(submitting: true, clearError: true);
    final String idToken;
    try {
      idToken = await ref.read(googleAuthServiceProvider).obtainIdToken();
    } on CancelledException {
      // User aborted — not an error.
      if (ref.mounted) state = state.copyWith(submitting: false);
      return false;
    } on AppException catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          submitting: false,
          errorMessage: e.message ?? 'Google sign-in failed',
        );
      }
      return false;
    }
    if (!ref.mounted) return false;
    return googleSignIn(idToken);
  }

  /// Requests a password-reset email. Always reports success (no enumeration).
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(submitting: true, clearError: true, clearInfo: true);
    final result =
        await ref.read(authRepositoryProvider).forgotPassword(email: email);
    if (!ref.mounted) return;
    switch (result) {
      case Success():
        state = state.copyWith(
          submitting: false,
          infoMessage: 'If that email exists, a reset link has been sent.',
        );
      case ResultFailure(:final failure):
        state = state.copyWith(submitting: false, errorMessage: failure.message);
    }
  }

  /// Completes a password reset. Returns true on success.
  Future<bool> resetPassword(String token, String password) async {
    state = state.copyWith(submitting: true, clearError: true, clearInfo: true);
    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(token: token, password: password);
    if (!ref.mounted) return false;
    switch (result) {
      case Success():
        state = state.copyWith(
          submitting: false,
          infoMessage: 'Password updated. Please sign in.',
        );
        return true;
      case ResultFailure(:final failure):
        state = state.copyWith(submitting: false, errorMessage: failure.message);
        return false;
    }
  }

  Future<void> logout() async {
    final refresh =
        await ref.read(authLocalDataSourceProvider).readRefreshToken();
    if (refresh != null) {
      await ref.read(authRepositoryProvider).logout(refreshToken: refresh);
    }
    await ref.read(authLocalDataSourceProvider).clear();
    _onSignedOut();
  }

  /// Shared submit path for the three sign-in flows.
  Future<bool> _authenticate(
    Future<Result<AuthSession>> Function() action,
  ) async {
    state = state.copyWith(submitting: true, clearError: true, fieldErrors: {});
    final result = await action();
    if (!ref.mounted) return false;

    switch (result) {
      case Success(:final value):
        await ref.read(authLocalDataSourceProvider).persistSession(value);
        if (!ref.mounted) return false;
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: value.user,
          submitting: false,
        );
        return true;
      case ResultFailure(:final failure):
        state = state.copyWith(
          submitting: false,
          errorMessage: failure.message,
          fieldErrors:
              failure is ValidationFailure ? failure.fieldErrors : const {},
        );
        return false;
    }
  }
}
