import 'package:moid_share/core/storage/key_value_store.dart';

/// In-memory [KeyValueStore] for tests — no Hive, no disk.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object?> _data = {};

  @override
  T? get<T>(String key, {T? defaultValue}) =>
      (_data[key] as T?) ?? defaultValue;

  @override
  Future<void> set<T>(String key, T value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();

  @override
  bool containsKey(String key) => _data.containsKey(key);
}
