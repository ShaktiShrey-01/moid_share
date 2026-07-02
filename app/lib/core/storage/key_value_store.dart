import 'package:hive_ce_flutter/hive_flutter.dart';

import '../error/exceptions.dart';

/// Contract for non-sensitive local key/value persistence (settings, cached
/// device list, transfer history). NEVER store secrets here — use
/// [SecureStorage] for tokens.
abstract interface class KeyValueStore {
  T? get<T>(String key, {T? defaultValue});
  Future<void> set<T>(String key, T value);
  Future<void> remove(String key);
  Future<void> clear();
  bool containsKey(String key);
}

/// [KeyValueStore] backed by a single Hive box.
///
/// One instance wraps one box; obtain instances via the DI providers so the
/// box lifecycle (open/close) is centrally managed.
class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore(this._box);

  final Box<dynamic> _box;

  @override
  T? get<T>(String key, {T? defaultValue}) {
    try {
      return _box.get(key, defaultValue: defaultValue) as T?;
    } catch (e, s) {
      throw CacheException('Hive read failed for "$key"', e, s);
    }
  }

  @override
  Future<void> set<T>(String key, T value) async {
    try {
      await _box.put(key, value);
    } catch (e, s) {
      throw CacheException('Hive write failed for "$key"', e, s);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _box.delete(key);
    } catch (e, s) {
      throw CacheException('Hive delete failed for "$key"', e, s);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (e, s) {
      throw CacheException('Hive clear failed', e, s);
    }
  }

  @override
  bool containsKey(String key) => _box.containsKey(key);
}
