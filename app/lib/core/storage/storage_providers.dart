import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'key_value_store.dart';
import 'secure_storage.dart';

/// DI wiring for the storage layer.
///
/// The Hive-backed [KeyValueStore] providers throw until overridden in
/// `bootstrap.dart` with the boxes opened by [StorageInitializer]. This keeps
/// box construction async-at-boot while consumers see a synchronous store.

/// Secret storage (JWTs). Safe to construct eagerly — no async open needed.
final secureStorageProvider = Provider<SecureStorage>(
  (ref) => SecureStorageImpl(),
);

/// App settings (theme, preferences). Overridden at bootstrap.
final settingsStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError(
    'settingsStoreProvider must be overridden in bootstrap with the opened box',
  ),
);

/// Cached registered/paired devices. Overridden at bootstrap.
final devicesStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError(
    'devicesStoreProvider must be overridden in bootstrap with the opened box',
  ),
);

/// Local transfer history. Overridden at bootstrap.
final transferHistoryStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError(
    'transferHistoryStoreProvider must be overridden in bootstrap with the box',
  ),
);

/// Local clipboard history. Overridden at bootstrap.
final clipboardStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError(
    'clipboardStoreProvider must be overridden in bootstrap with the box',
  ),
);
