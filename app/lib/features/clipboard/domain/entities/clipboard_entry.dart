/// Where a clipboard entry came from.
enum ClipboardOrigin { local, remote }

/// A single clipboard item in the sync history (domain entity).
class ClipboardEntry {
  const ClipboardEntry({
    required this.id,
    required this.content,
    required this.origin,
    this.contentType = 'text/plain',
    this.fromDeviceId,
    required this.createdAt,
  });

  final String id;
  final String content;
  final ClipboardOrigin origin;
  final String contentType;
  final String? fromDeviceId;
  final DateTime createdAt;

  /// A short preview for list rows.
  String get preview {
    final single = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return single.length <= 120 ? single : '${single.substring(0, 120)}…';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'origin': origin.name,
        'contentType': contentType,
        'fromDeviceId': fromDeviceId,
        'createdAt': createdAt.toIso8601String(),
      };

  static ClipboardEntry fromJson(Map<String, dynamic> json) => ClipboardEntry(
        id: json['id'] as String,
        content: json['content'] as String,
        origin: ClipboardOrigin.values.firstWhere(
          (o) => o.name == json['origin'],
          orElse: () => ClipboardOrigin.local,
        ),
        contentType: json['contentType'] as String? ?? 'text/plain',
        fromDeviceId: json['fromDeviceId'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'].toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
