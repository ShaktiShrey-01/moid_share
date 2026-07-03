import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../../../core/platform/platform_seams.dart';
import '../../../core/realtime/socket_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/repositories/transfer_repository.dart';
import '../presentation/controllers/transfer_controller.dart';
import '../presentation/controllers/transfer_state.dart';
import 'datasources/transfer_bridge.dart';
import 'datasources/transfer_local_datasource.dart';
import 'managers/connection_manager.dart';
import 'managers/discovery_manager.dart';
import 'managers/encryption_manager.dart';
import 'managers/transfer_manager.dart';
import 'managers/transfer_socket_manager.dart';
import 'repositories/transfer_repository_impl.dart';

/// Dependency injection for the transfer feature.

// -- native seams --------------------------------------------------------

final transferSenderBridgeProvider = Provider<TransferSenderBridge>(
  (ref) => MethodChannelTransferSenderBridge(),
);

final transferReceiverBridgeProvider = Provider<TransferReceiverBridge>(
  (ref) => MethodChannelTransferReceiverBridge(),
);

final discoveryBridgeProvider = Provider<DiscoveryBridge>(
  (ref) => throw UnimplementedError(
    'DiscoveryBridge is a native seam; provide a platform implementation '
    '(Kotlin now, Swift later) or override in tests.',
  ),
);

// -- managers ------------------------------------------------------------

final encryptionManagerProvider = Provider<EncryptionManager>(
  (ref) => AesGcmEncryptionManager(),
);

final connectionManagerProvider = Provider<ConnectionManager>(
  (ref) => UnconnectedConnectionManager(),
);

final transferSocketManagerProvider = Provider<TransferSocketManager>(
  (ref) => TransferSocketManager(ref.watch(socketManagerProvider)),
);

final discoveryManagerProvider = Provider<DiscoveryManager>(
  (ref) => DiscoveryManager(ref.watch(discoveryBridgeProvider)),
);

final transferManagerProvider = Provider<TransferManager>((ref) {
  final manager = TransferManager(
    signalingManager: ref.watch(transferSocketManagerProvider),
    encryptionManager: ref.watch(encryptionManagerProvider),
    connectionManager: ref.watch(connectionManagerProvider),
    senderBridge: ref.watch(transferSenderBridgeProvider),
    appLogger: ref.watch(loggerProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

// -- data ----------------------------------------------------------------

final transferLocalDataSourceProvider = Provider<TransferLocalDataSource>(
  (ref) => TransferLocalDataSource(ref.watch(transferHistoryStoreProvider)),
);

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  final repo = TransferRepositoryImpl(
    transferManager: ref.watch(transferManagerProvider),
    signalingManager: ref.watch(transferSocketManagerProvider),
    localDataSource: ref.watch(transferLocalDataSourceProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

// -- presentation --------------------------------------------------------

final transferControllerProvider =
    NotifierProvider<TransferController, TransferState>(
  TransferController.new,
);
