import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/transfer_item.dart';

/// Persists a bounded, most-recent-first transfer history in Hive.
///
/// Metadata only — file names, sizes, status and timestamps. The file bytes
/// themselves are never stored, matching the backend's "never store files"
/// rule. Records are keyed by transfer id so status updates replace in place.
class TransferLocalDataSource {
  TransferLocalDataSource(this._store);

  static const String _key = 'transfer.history';
  static const int _maxItems = 200;

  final KeyValueStore _store;

  List<TransferItem> read() {
    final raw = _store.get<String>(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => TransferItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a new record or replaces an existing one with the same id,
  /// keeping the list most-recent-first.
  Future<void> upsert(TransferItem item) async {
    final items = read()..removeWhere((e) => e.id == item.id);
    items.insert(0, item);
    if (items.length > _maxItems) items.removeRange(_maxItems, items.length);
    await _persist(items);
  }

  Future<void> clear() => _store.remove(_key);

  Future<void> _persist(List<TransferItem> items) => _store.set(
        _key,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
}
