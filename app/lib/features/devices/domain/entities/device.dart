/// A device registered to the current user (domain entity).
class Device {
  const Device({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.platform,
    this.model,
    this.lastSeenAt,
    this.pairedWith = const [],
    this.createdAt,
    this.isCurrent = false,
  });

  final String id;
  final String deviceId;
  final String name;

  /// One of: android, ios, macos, windows, linux, web, unknown.
  final String platform;
  final String? model;
  final DateTime? lastSeenAt;
  final List<String> pairedWith;
  final DateTime? createdAt;

  /// True if this row represents the device the app is currently running on.
  final bool isCurrent;

  bool get isPaired => pairedWith.isNotEmpty;

  Device copyWith({bool? isCurrent}) => Device(
        id: id,
        deviceId: deviceId,
        name: name,
        platform: platform,
        model: model,
        lastSeenAt: lastSeenAt,
        pairedWith: pairedWith,
        createdAt: createdAt,
        isCurrent: isCurrent ?? this.isCurrent,
      );
}
