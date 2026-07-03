import 'package:hive_ce_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Opens Hive and all application boxes during app bootstrap.
///
/// Called once before `runApp`. The opened boxes are then injected into the
/// provider graph (see `storage_providers.dart`) via `ProviderScope` overrides,
/// so the rest of the app consumes already-open boxes synchronously.
class StorageInitializer {
  const StorageInitializer();

  /// Initializes Hive and opens every box the app needs.
  ///
  /// Returns the opened boxes so [bootstrap] can wire them into DI.
  Future<OpenedBoxes> initialize() async {
    await Hive.initFlutter();

    // NOTE: Register generated Hive adapters here as models are introduced,
    // e.g. `Hive.registerAdapter(DeviceModelAdapter());`

    final settings = await Hive.openBox<dynamic>(HiveBoxes.settings);
    final devices = await Hive.openBox<dynamic>(HiveBoxes.devices);
    final history = await Hive.openBox<dynamic>(HiveBoxes.transferHistory);
    final clipboard = await Hive.openBox<dynamic>(HiveBoxes.clipboard);

    return OpenedBoxes(
      settings: settings,
      devices: devices,
      transferHistory: history,
      clipboard: clipboard,
    );
  }
}

/// Value object holding the app's opened Hive boxes.
class OpenedBoxes {
  const OpenedBoxes({
    required this.settings,
    required this.devices,
    required this.transferHistory,
    required this.clipboard,
  });

  final Box<dynamic> settings;
  final Box<dynamic> devices;
  final Box<dynamic> transferHistory;
  final Box<dynamic> clipboard;
}
