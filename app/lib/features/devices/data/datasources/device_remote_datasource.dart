import '../../../../core/network/api_client.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/pairing_start.dart';
import '../models/device_model.dart';

/// Talks to the backend `/devices` endpoints via [ApiClient]. Lets thrown
/// [AppException]s propagate for the repository to map.
class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Device> registerCurrent({
    required String deviceId,
    required String name,
    required String platform,
    String? model,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/devices',
      data: {
        'deviceId': deviceId,
        'name': name,
        'platform': platform,
        'model': ?model,
      },
    );
    return DeviceModel.fromJson(_data(res.data)['device'] as Map<String, dynamic>);
  }

  Future<List<Device>> list() async {
    final res = await _api.get<Map<String, dynamic>>('/devices');
    final list = _data(res.data)['devices'] as List? ?? const [];
    return list
        .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revoke(String deviceId) async {
    await _api.delete<Map<String, dynamic>>('/devices/$deviceId');
  }

  Future<PairingStart> startPairing(String initiatorDeviceId) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/devices/pair/start',
      data: {'initiatorDeviceId': initiatorDeviceId},
    );
    final data = _data(res.data);
    return PairingStart(
      code: data['code'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Future<void> completePairing({
    required String code,
    required String deviceId,
  }) async {
    await _api.post<Map<String, dynamic>>(
      '/devices/pair/complete',
      data: {'code': code, 'deviceId': deviceId},
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Malformed response: missing "data"');
  }
}
