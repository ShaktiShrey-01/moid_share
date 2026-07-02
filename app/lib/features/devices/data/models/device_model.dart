import '../../domain/entities/device.dart';

/// Maps backend device JSON (`Device.toPublicJSON`) to a [Device] entity.
abstract final class DeviceModel {
  static Device fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        name: json['name'] as String? ?? 'Device',
        platform: json['platform'] as String? ?? 'unknown',
        model: json['model'] as String?,
        lastSeenAt: json['lastSeenAt'] != null
            ? DateTime.tryParse(json['lastSeenAt'].toString())
            : null,
        pairedWith:
            (json['pairedWith'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
}
