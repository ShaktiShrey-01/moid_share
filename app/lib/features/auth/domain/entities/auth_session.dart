import 'auth_tokens.dart';
import 'auth_user.dart';

/// A successful authentication: the user plus their token pair.
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final AuthTokens tokens;
}
