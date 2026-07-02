import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coarse authentication state used by the router guard.
///
/// This is a deliberately tiny seam so `core/router` can gate navigation
/// without depending on the auth feature. The auth feature will OVERRIDE
/// [authStatusProvider] with a real notifier derived from token/session state.
enum AuthStatus {
  /// Still determining session state (e.g. reading tokens at startup).
  unknown,

  /// A valid session exists.
  authenticated,

  /// No valid session; user must sign in.
  unauthenticated,
}

/// Current [AuthStatus].
///
/// Default is [AuthStatus.unauthenticated]: with no auth feature wired yet, the
/// app correctly lands on the unauthenticated (welcome) surface. Once the auth
/// feature exists it overrides this provider with live session state, and the
/// router guard immediately begins enforcing real authentication.
final authStatusProvider = Provider<AuthStatus>(
  (ref) => AuthStatus.unauthenticated,
);
