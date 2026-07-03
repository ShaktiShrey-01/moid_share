import '../../domain/entities/transfer_item.dart';
import '../../domain/entities/transfer_offer.dart';

/// UI state for the transfer feature.
class TransferState {
  const TransferState({
    this.history = const [],
    this.active = const [],
    this.pendingOffer,
    this.notice,
    this.error,
  });

  /// Persisted, most-recent-first transfer history.
  final List<TransferItem> history;

  /// In-flight transfers (offered/active), keyed order by recency.
  final List<TransferItem> active;

  /// The incoming offer currently awaiting the user's accept/reject, if any.
  final TransferOffer? pendingOffer;

  final String? notice;
  final String? error;

  TransferState copyWith({
    List<TransferItem>? history,
    List<TransferItem>? active,
    TransferOffer? pendingOffer,
    bool clearPendingOffer = false,
    String? notice,
    bool clearNotice = false,
    String? error,
    bool clearError = false,
  }) {
    return TransferState(
      history: history ?? this.history,
      active: active ?? this.active,
      pendingOffer:
          clearPendingOffer ? null : (pendingOffer ?? this.pendingOffer),
      notice: clearNotice ? null : (notice ?? this.notice),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
