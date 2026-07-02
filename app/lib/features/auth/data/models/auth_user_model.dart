import '../../domain/entities/auth_user.dart';

/// Maps the backend user JSON (`User.toPublicJSON`) to/from [AuthUser].
///
/// Kept in the data layer so the domain entity stays serialization-free.
abstract final class AuthUserModel {
  static AuthUser fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        providers:
            (json['providers'] as List?)?.map((e) => e.toString()).toList() ??
                const ['local'],
        emailVerified: json['emailVerified'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  /// Serializes for local persistence (Hive) — round-trips [fromJson].
  static Map<String, dynamic> toJson(AuthUser user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'avatarUrl': user.avatarUrl,
        'providers': user.providers,
        'emailVerified': user.emailVerified,
        'createdAt': user.createdAt?.toIso8601String(),
      };
}
