/// Access + refresh token pair issued by the backend (domain entity).
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.accessExpiresIn = 0,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  /// Access-token lifetime in seconds (used for proactive refresh scheduling).
  final int accessExpiresIn;
}
