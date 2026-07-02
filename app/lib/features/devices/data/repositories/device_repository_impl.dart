import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/pairing_start.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device_remote_datasource.dart';

/// [DeviceRepository] implementation: calls the datasource and maps thrown
/// [AppException]s to [Failure]s via [mapExceptionToFailure].
class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._remote);

  final DeviceRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Device>> registerCurrent({
    required String deviceId,
    required String name,
    required String platform,
    String? model,
  }) =>
      _guard(() => _remote.registerCurrent(
            deviceId: deviceId,
            name: name,
            platform: platform,
            model: model,
          ));

  @override
  Future<Result<List<Device>>> list() => _guard(_remote.list);

  @override
  Future<Result<void>> revoke(String deviceId) =>
      _guard(() => _remote.revoke(deviceId));

  @override
  Future<Result<PairingStart>> startPairing(String initiatorDeviceId) =>
      _guard(() => _remote.startPairing(initiatorDeviceId));

  @override
  Future<Result<void>> completePairing({
    required String code,
    required String deviceId,
  }) =>
      _guard(() => _remote.completePairing(code: code, deviceId: deviceId));
}
