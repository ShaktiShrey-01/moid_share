import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/features/transfer/data/transfer_providers.dart';
import 'package:moid_share/features/transfer/domain/entities/transfer_item.dart';
import 'package:moid_share/features/transfer/domain/entities/transfer_offer.dart';
import 'package:moid_share/features/transfer/domain/repositories/transfer_repository.dart';

/// Fake repo driving offers/progress via controllers the test can push to.
class _FakeTransferRepository implements TransferRepository {
  _FakeTransferRepository({List<TransferItem>? initial})
      : _history = [...?initial];

  final List<TransferItem> _history;
  final _offers = StreamController<TransferOffer>.broadcast();
  final _progress = StreamController<TransferItem>.broadcast();

  TransferItem sendResult = _item('f1', TransferStatus.offered);
  TransferOffer? accepted;
  TransferOffer? rejected;
  String? cancelledId;
  bool cleared = false;

  @override
  Future<TransferItem> sendFile() async => sendResult;

  @override
  Future<TransferItem> accept(TransferOffer offer) async {
    accepted = offer;
    return _fromOffer(offer, TransferStatus.accepted);
  }

  @override
  Future<void> reject(TransferOffer offer, {String? reason}) async =>
      rejected = offer;

  @override
  Future<void> cancel(String transferId, {String? reason}) async =>
      cancelledId = transferId;

  @override
  Stream<TransferOffer> incomingOffers() => _offers.stream;

  @override
  Stream<TransferItem> progress() => _progress.stream;

  @override
  Future<List<TransferItem>> history() async => List.unmodifiable(_history);

  @override
  Future<void> record(TransferItem item) async => _history.insert(0, item);

  @override
  Future<void> clearHistory() async {
    cleared = true;
    _history.clear();
  }

  // test helpers
  void pushOffer(TransferOffer o) => _offers.add(o);
  void pushProgress(TransferItem t) => _progress.add(t);

  static TransferItem _fromOffer(TransferOffer o, TransferStatus s) =>
      TransferItem(
        id: o.transferId,
        fileName: o.fileName,
        size: o.size,
        direction: TransferDirection.incoming,
        status: s,
        createdAt: o.receivedAt,
      );
}

TransferItem _item(String id, TransferStatus status,
        {TransferDirection dir = TransferDirection.outgoing}) =>
    TransferItem(
      id: id,
      fileName: '$id.bin',
      size: 100,
      direction: dir,
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );

TransferOffer _offer(String id) => TransferOffer(
      transferId: id,
      fileName: '$id.pdf',
      size: 2048,
      fromDeviceId: 'peer',
      receivedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeTransferRepository repo;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [transferRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = _FakeTransferRepository());

  test('loads history on build', () async {
    repo = _FakeTransferRepository(
      initial: [_item('a', TransferStatus.completed)],
    );
    final container = makeContainer();
    container.read(transferControllerProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(transferControllerProvider).history.single.id, 'a');
  });

  test('incoming offer becomes the pending offer', () async {
    final container = makeContainer();
    container.read(transferControllerProvider); // build + subscribe
    await Future<void>.delayed(Duration.zero);

    repo.pushOffer(_offer('t1'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(transferControllerProvider).pendingOffer?.transferId,
        't1');
  });

  test('sendFile surfaces an offered notice', () async {
    repo.sendResult = _item('f1', TransferStatus.offered);
    final container = makeContainer();

    await container.read(transferControllerProvider.notifier).sendFile();

    expect(container.read(transferControllerProvider).notice,
        contains('Offered'));
  });

  test('accepting clears the pending offer and calls the repo', () async {
    final container = makeContainer();
    container.read(transferControllerProvider);
    await Future<void>.delayed(Duration.zero);
    repo.pushOffer(_offer('t1'));
    await Future<void>.delayed(Duration.zero);

    await container.read(transferControllerProvider.notifier).acceptPending();

    expect(repo.accepted?.transferId, 't1');
    expect(container.read(transferControllerProvider).pendingOffer, isNull);
  });

  test('rejecting clears the pending offer and calls the repo', () async {
    final container = makeContainer();
    container.read(transferControllerProvider);
    await Future<void>.delayed(Duration.zero);
    repo.pushOffer(_offer('t2'));
    await Future<void>.delayed(Duration.zero);

    await container.read(transferControllerProvider.notifier).rejectPending();

    expect(repo.rejected?.transferId, 't2');
    expect(container.read(transferControllerProvider).pendingOffer, isNull);
  });

  test('active progress lands in active, terminal lands in history', () async {
    final container = makeContainer();
    container.read(transferControllerProvider);
    await Future<void>.delayed(Duration.zero);

    repo.pushProgress(_item('x', TransferStatus.active));
    await Future<void>.delayed(Duration.zero);
    var state = container.read(transferControllerProvider);
    expect(state.active.single.id, 'x');
    expect(state.history, isEmpty);

    repo.pushProgress(_item('x', TransferStatus.completed));
    await Future<void>.delayed(Duration.zero);
    state = container.read(transferControllerProvider);
    expect(state.active, isEmpty);
    expect(state.history.single.id, 'x');
  });

  test('clearHistory empties history via the repo', () async {
    repo = _FakeTransferRepository(
      initial: [_item('a', TransferStatus.completed)],
    );
    final container = makeContainer();
    container.read(transferControllerProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(transferControllerProvider.notifier).clearHistory();

    expect(repo.cleared, isTrue);
    expect(container.read(transferControllerProvider).history, isEmpty);
  });
}
