/// A signed-in user's public profile (domain entity).
///
/// Pure Dart, framework-free. The data layer maps the backend's `toPublicJSON`
/// shape into this; the presentation layer renders it.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.providers = const ['local'],
    this.emailVerified = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final List<String> providers;
  final bool emailVerified;
  final DateTime? createdAt;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
