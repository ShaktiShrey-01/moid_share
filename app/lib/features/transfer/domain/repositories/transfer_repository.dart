import '../../../../core/platform/platform_seams.dart';
import '../entities/transfer_item.dart';
import '../entities/transfer_offer.dart';

/// File-transfer contract.
///
/// Combines three concerns behind one interface, mirroring the clipboard
/// repository shape:
///   * **signaling** — offer/accept/reject/cancel over the realtime channel,
///     plus the stream of incoming offers,
///   * **byte transfer** — driving the actual send (the receive side is a
///     native seam), surfaced as a progress stream,
///   * **history** — locally-persisted transfer records (metadata only; the
///     backend never stores files).
abstract interface class TransferRepository {
  /// Offers a picked file to the user's other devices. Emits progress via
  /// [progress]; returns the created [TransferItem] (status [TransferStatus.offered]).
  Future<TransferItem> sendFile();

  /// Offers an already-resolved [file] (e.g. from the Android share sheet).
  Future<TransferItem> sendSharedFile(PickedFile file);

  /// Files handed to the app via the OS share sheet.
  Stream<PickedFile> sharedFiles();

  /// Accepts an incoming [offer] and begins receiving over the native seam.
  Future<TransferItem> accept(TransferOffer offer);

  /// Rejects an incoming [offer].
  Future<void> reject(TransferOffer offer, {String? reason});

  /// Cancels an in-flight transfer by id.
  Future<void> cancel(String transferId, {String? reason});

  /// Stream of offers relayed from the user's other devices.
  Stream<TransferOffer> incomingOffers();

  /// Stream of live progress/status updates for active transfers.
  Stream<TransferItem> progress();

  /// Locally-persisted transfer history (most recent first).
  Future<List<TransferItem>> history();
  Future<void> record(TransferItem item);
  Future<void> clearHistory();
}
