import '../../../../core/realtime/socket_manager.dart';
import '../../domain/entities/clipboard_entry.dart';
import '../../domain/repositories/clipboard_repository.dart';
import '../clipboard_service.dart';
import '../datasources/clipboard_local_datasource.dart';

/// [ClipboardRepository] implementation.
///
/// Composes the realtime channel ([SocketManager]), the system clipboard
/// ([ClipboardService]) and local history ([ClipboardLocalDataSource]).
/// Incoming payloads are relayed by the backend from the user's other devices;
/// nothing clipboard-related is ever sent to the REST API.
class ClipboardRepositoryImpl implements ClipboardRepository {
  ClipboardRepositoryImpl({
    required SocketManager socketManager,
    required ClipboardService clipboardService,
    required ClipboardLocalDataSource localDataSource,
  })  : _socket = socketManager,
        _service = clipboardService,
        _local = localDataSource;

  static const String _syncEvent = 'clipboard:sync';
  static const String _incomingEvent = 'clipboard:incoming';

  final SocketManager _socket;
  final ClipboardService _service;
  final ClipboardLocalDataSource _local;

  int _seq = 0;

  @override
  Stream<ClipboardEntry> incoming() => _socket.on(_incomingEvent).map((data) {
        final map = Map<String, dynamic>.from(data as Map);
        return ClipboardEntry(
          id: 'r${DateTime.now().microsecondsSinceEpoch}_${_seq++}',
          content: map['content'] as String? ?? '',
          origin: ClipboardOrigin.remote,
          contentType: map['contentType'] as String? ?? 'text/plain',
          fromDeviceId: map['fromDeviceId'] as String?,
          createdAt: DateTime.tryParse(map['at']?.toString() ?? '') ??
              DateTime.now(),
        );
      });

  @override
  Future<bool> push(String content, {String contentType = 'text/plain'}) async {
    final ack = await _socket.emitWithAck(
      _syncEvent,
      {'content': content, 'contentType': contentType},
    );
    return ack?['ok'] == true;
  }

  @override
  Future<String?> readSystemClipboard() => _service.read();

  @override
  Future<void> writeSystemClipboard(String content) =>
      _service.write(content);

  @override
  Future<List<ClipboardEntry>> history() async => _local.read();

  @override
  Future<void> addToHistory(ClipboardEntry entry) => _local.add(entry);

  @override
  Future<void> clearHistory() => _local.clear();
}
