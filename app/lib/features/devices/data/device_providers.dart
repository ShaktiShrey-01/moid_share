import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/entities/device.dart';
import '../domain/repositories/device_repository.dart';
import '../presentation/controllers/devices_controller.dart';
import 'datasources/device_remote_datasource.dart';
import 'device_identity.dart';
import 'repositories/device_repository_impl.dart';

/// Dependency injection for the devices feature.

final deviceIdentityProvider = Provider<DeviceIdentity>(
  (ref) => DeviceIdentity(ref.watch(secureStorageProvider)),
);

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>(
  (ref) => DeviceRemoteDataSource(ref.watch(apiClientProvider)),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepositoryImpl(ref.watch(deviceRemoteDataSourceProvider)),
);

/// Async list of the user's devices, with the current device registered on load.
final devicesControllerProvider =
    AsyncNotifierProvider<DevicesController, List<Device>>(
  DevicesController.new,
);
