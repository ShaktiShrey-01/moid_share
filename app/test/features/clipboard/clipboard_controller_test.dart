import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/features/clipboard/data/clipboard_providers.dart';
import 'package:moid_share/features/clipboard/domain/entities/clipboard_entry.dart';
import 'package:moid_share/features/clipboard/domain/repositories/clipboard_repository.dart';

/// Fake repo: in-memory history + system clipboard, records pushes. No socket,
/// no platform channels.
class _FakeClipboardRepository implements ClipboardRepository {
  _FakeClipboardRepository({List<ClipboardEntry>? initial})
      : _history = [...?initial];

  final List<ClipboardEntry> _history;
  final _incoming = StreamController<ClipboardEntry>.broadcast();

  String? systemClipboard;
  final List<String> pushed = [];
  bool pushAck = true;

  @override
  Stream<ClipboardEntry> incoming() => _incoming.stream;

  @override
  Future<bool> push(String content, {String contentType = 'text/plain'}) async {
    pushed.add(content);
    return pushAck;
  }

  @override
  Future<String?> readSystemClipboard() async => systemClipboard;

  @override
  Future<void> writeSystemClipboard(String content) async =>
      systemClipboard = content;

  @override
  Future<List<ClipboardEntry>> history() async => List.unmodifiable(_history);

  @override
  Future<void> addToHistory(ClipboardEntry entry) async =>
      _history.insert(0, entry);

  @override
  Future<void> clearHistory() async => _history.clear();
}

ClipboardEntry _entry(String content) => ClipboardEntry(
      id: content,
      content: content,
      origin: ClipboardOrigin.remote,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeClipboardRepository repo;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        clipboardRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = _FakeClipboardRepository());

  test('loads history on build', () async {
    repo = _FakeClipboardRepository(initial: [_entry('a'), _entry('b')]);
    final container = makeContainer();

    container.read(clipboardControllerProvider); // trigger build
    await Future<void>.delayed(Duration.zero); // let _loadHistory microtask run

    final state = container.read(clipboardControllerProvider);
    expect(state.history.map((e) => e.content), ['a', 'b']);
  });

  test('sendCurrentClipboard with empty clipboard sets a notice', () async {
    final container = makeContainer();
    repo.systemClipboard = '   ';

    await container
        .read(clipboardControllerProvider.notifier)
        .sendCurrentClipboard();

    final state = container.read(clipboardControllerProvider);
    expect(state.notice, 'Clipboard is empty');
    expect(repo.pushed, isEmpty);
  });

  test('sendCurrentClipboard pushes text and records it in history', () async {
    final container = makeContainer();
    repo.systemClipboard = 'hello';

    await container
        .read(clipboardControllerProvider.notifier)
        .sendCurrentClipboard();

    final state = container.read(clipboardControllerProvider);
    expect(repo.pushed, ['hello']);
    expect(state.history.first.content, 'hello');
    expect(state.history.first.origin, ClipboardOrigin.local);
    expect(state.notice, 'Sent to your devices');
  });

  test('sendCurrentClipboard notes offline save when push is not acked',
      () async {
    final container = makeContainer();
    repo
      ..systemClipboard = 'hello'
      ..pushAck = false;

    await container
        .read(clipboardControllerProvider.notifier)
        .sendCurrentClipboard();

    final state = container.read(clipboardControllerProvider);
    expect(state.notice, 'Saved locally (offline)');
  });

  test('applyToClipboard writes system clipboard and notices', () async {
    final container = makeContainer();

    await container
        .read(clipboardControllerProvider.notifier)
        .applyToClipboard(_entry('copy-me'));

    expect(repo.systemClipboard, 'copy-me');
    expect(container.read(clipboardControllerProvider).notice,
        'Copied to clipboard');
  });

  test('clearHistory empties the history', () async {
    repo = _FakeClipboardRepository(initial: [_entry('a')]);
    final container = makeContainer();
    container.read(clipboardControllerProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(clipboardControllerProvider.notifier).clearHistory();

    expect(container.read(clipboardControllerProvider).history, isEmpty);
  });
}
