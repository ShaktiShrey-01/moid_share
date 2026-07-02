import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../data/device_providers.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/pairing_start.dart';

/// Loads and mutates the user's device list.
///
/// On first load it registers (upserts) the current device so it always
/// appears, then fetches the full list and flags the current device.
class DevicesController extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() => _registerAndList();

  Future<List<Device>> _registerAndList() async {
    final current = await ref.read(deviceIdentityProvider).resolve();
    final repo = ref.read(deviceRepositoryProvider);

    // Best-effort register (upsert). Ignore failure so listing still works.
    await repo.registerCurrent(
      deviceId: current.deviceId,
      name: current.name,
      platform: current.platform,
      model: current.model,
    );

    final result = await repo.list();
    final devices = switch (result) {
      Success(:final value) => value,
      ResultFailure(:final failure) => throw failure,
    };

    return devices
        .map((d) =>
            d.deviceId == current.deviceId ? d.copyWith(isCurrent: true) : d)
        .toList(growable: false);
  }

  /// Re-fetches the device list.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_registerAndList);
  }

  /// Removes a device, then refreshes. Returns the [Failure] if it failed.
  Future<Failure?> revoke(String deviceId) async {
    final result = await ref.read(deviceRepositoryProvider).revoke(deviceId);
    switch (result) {
      case Success():
        await refresh();
        return null;
      case ResultFailure(:final failure):
        return failure;
    }
  }

  /// Starts pairing for the current device.
  Future<Result<PairingStart>> startPairing() async {
    final current = await ref.read(deviceIdentityProvider).resolve();
    return ref.read(deviceRepositoryProvider).startPairing(current.deviceId);
  }

  /// Completes pairing using a [code] entered on this device; refreshes on ok.
  Future<Result<void>> completePairing(String code) async {
    final current = await ref.read(deviceIdentityProvider).resolve();
    final result = await ref
        .read(deviceRepositoryProvider)
        .completePairing(code: code, deviceId: current.deviceId);
    if (result is Success<void>) await refresh();
    return result;
  }
}
