import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/core/error/failure.dart';
import 'package:moid_share/core/error/result.dart';
import 'package:moid_share/features/devices/data/device_identity.dart';
import 'package:moid_share/features/devices/data/device_providers.dart';
import 'package:moid_share/features/devices/domain/entities/device.dart';
import 'package:moid_share/features/devices/domain/entities/pairing_start.dart';
import 'package:moid_share/features/devices/domain/repositories/device_repository.dart';
import 'package:moid_share/core/storage/storage_providers.dart';

import '../../helpers/in_memory_secure_storage.dart';

/// Fake repo capturing calls and returning scripted results.
class _FakeDeviceRepository implements DeviceRepository {
  List<Device> devices = const [];
  String? revokedId;

  @override
  Future<Result<Device>> registerCurrent({
    required String deviceId,
    required String name,
    required String platform,
    String? model,
  }) async =>
      Result.success(
        Device(id: 'x', deviceId: deviceId, name: name, platform: platform),
      );

  @override
  Future<Result<List<Device>>> list() async => Result.success(devices);

  @override
  Future<Result<void>> revoke(String deviceId) async {
    revokedId = deviceId;
    devices = devices.where((d) => d.deviceId != deviceId).toList();
    return const Result.success(null);
  }

  @override
  Future<Result<PairingStart>> startPairing(String initiatorDeviceId) async =>
      Result.failure(const NetworkFailure());

  @override
  Future<Result<void>> completePairing({
    required String code,
    required String deviceId,
  }) async =>
      const Result.success(null);
}

void main() {
  late _FakeDeviceRepository repo;

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(repo),
        secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
        // Deterministic identity: fixed device id.
        deviceIdentityProvider.overrideWithValue(
          _FixedIdentity(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => repo = _FakeDeviceRepository());

  test('loads devices and flags the current device', () async {
    repo.devices = const [
      Device(id: '1', deviceId: 'this-device-id', name: 'Pixel', platform: 'android'),
      Device(id: '2', deviceId: 'other', name: 'Mac', platform: 'macos'),
    ];
    final container = makeContainer();
    final devices =
        await container.read(devicesControllerProvider.future);

    expect(devices.length, 2);
    expect(devices.firstWhere((d) => d.deviceId == 'this-device-id').isCurrent,
        isTrue);
    expect(devices.firstWhere((d) => d.deviceId == 'other').isCurrent, isFalse);
  });

  test('revoke removes a device and refreshes', () async {
    repo.devices = const [
      Device(id: '1', deviceId: 'this-device-id', name: 'Pixel', platform: 'android'),
      Device(id: '2', deviceId: 'other', name: 'Mac', platform: 'macos'),
    ];
    final container = makeContainer();
    await container.read(devicesControllerProvider.future);

    final failure = await container
        .read(devicesControllerProvider.notifier)
        .revoke('other');

    expect(failure, isNull);
    expect(repo.revokedId, 'other');
    final devices = container.read(devicesControllerProvider).value!;
    expect(devices.any((d) => d.deviceId == 'other'), isFalse);
  });
}

/// Identity override returning a fixed device id (no platform channels).
class _FixedIdentity implements DeviceIdentity {
  @override
  Future<CurrentDevice> resolve() async => const CurrentDevice(
        deviceId: 'this-device-id',
        name: 'Test Device',
        platform: 'android',
      );

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
