import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/clipboard_entry.dart';

/// Persists a bounded, most-recent-first clipboard history in Hive.
class ClipboardLocalDataSource {
  ClipboardLocalDataSource(this._store);

  static const String _key = 'clipboard.history';
  static const int _maxItems = 100;

  final KeyValueStore _store;

  List<ClipboardEntry> read() {
    final raw = _store.get<String>(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => ClipboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> add(ClipboardEntry entry) async {
    final items = read();
    // De-dupe consecutive identical content.
    if (items.isNotEmpty && items.first.content == entry.content) return;
    items.insert(0, entry);
    if (items.length > _maxItems) items.removeRange(_maxItems, items.length);
    await _persist(items);
  }

  Future<void> clear() => _store.remove(_key);

  Future<void> _persist(List<ClipboardEntry> items) => _store.set(
        _key,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
}
