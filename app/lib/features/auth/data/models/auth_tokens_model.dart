import '../../domain/entities/auth_tokens.dart';

/// Maps the backend token JSON to [AuthTokens].
abstract final class AuthTokensModel {
  static AuthTokens fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        accessExpiresIn: (json['accessExpiresIn'] as num?)?.toInt() ?? 0,
      );
}
