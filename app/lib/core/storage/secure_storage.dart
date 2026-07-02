import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/exceptions.dart';

/// Contract for secret storage (JWTs, device id).
///
/// Abstracting the concrete plugin behind an interface lets us (a) inject a
/// fake in tests and (b) swap the backing store without touching callers.
/// ONLY secrets go here — everything else uses [KeyValueStore] (Hive).
abstract interface class SecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

/// [SecureStorage] backed by the platform keystore/keychain via
/// `flutter_secure_storage`.
///
/// On Android it uses `EncryptedSharedPreferences`; on Apple platforms the
/// Keychain with `first_unlock_this_device` accessibility so tokens survive
/// reboots but never leave the device.
class SecureStorageImpl implements SecureStorage {
  SecureStorageImpl([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, s) {
      throw CacheException('Secure write failed for "$key"', e, s);
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, s) {
      throw CacheException('Secure read failed for "$key"', e, s);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, s) {
      throw CacheException('Secure delete failed for "$key"', e, s);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (e, s) {
      throw CacheException('Secure clear failed', e, s);
    }
  }
}
