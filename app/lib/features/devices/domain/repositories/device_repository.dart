import '../../../../core/error/result.dart';
import '../entities/device.dart';
import '../entities/pairing_start.dart';

/// Devices domain contract. All methods return [Result] — never throw.
abstract interface class DeviceRepository {
  /// Registers/updates the current device (upsert) and returns it.
  Future<Result<Device>> registerCurrent({
    required String deviceId,
    required String name,
    required String platform,
    String? model,
  });

  Future<Result<List<Device>>> list();

  Future<Result<void>> revoke(String deviceId);

  /// Starts pairing from [initiatorDeviceId], returning a code to share.
  Future<Result<PairingStart>> startPairing(String initiatorDeviceId);

  /// Completes pairing by entering a [code] on this [deviceId].
  Future<Result<void>> completePairing({
    required String code,
    required String deviceId,
  });
}
