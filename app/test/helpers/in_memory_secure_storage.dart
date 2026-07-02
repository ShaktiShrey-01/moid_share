import 'package:moid_share/core/storage/secure_storage.dart';

/// In-memory [SecureStorage] for tests — no keychain, no platform channel.
class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();
}
