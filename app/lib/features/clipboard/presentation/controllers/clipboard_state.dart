import '../../domain/entities/clipboard_entry.dart';

/// UI state for the clipboard feature.
class ClipboardState {
  const ClipboardState({
    this.syncEnabled = false,
    this.connected = false,
    this.autoApply = true,
    this.history = const [],
    this.error,
    this.notice,
  });

  final bool syncEnabled;
  final bool connected;

  /// When true, incoming remote items are written to the system clipboard.
  final bool autoApply;
  final List<ClipboardEntry> history;
  final String? error;
  final String? notice;

  ClipboardState copyWith({
    bool? syncEnabled,
    bool? connected,
    bool? autoApply,
    List<ClipboardEntry>? history,
    String? error,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return ClipboardState(
      syncEnabled: syncEnabled ?? this.syncEnabled,
      connected: connected ?? this.connected,
      autoApply: autoApply ?? this.autoApply,
      history: history ?? this.history,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }
}
