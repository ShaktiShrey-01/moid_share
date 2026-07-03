import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_seams.dart';
import '../../../core/realtime/socket_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/repositories/clipboard_repository.dart';
import '../presentation/controllers/clipboard_controller.dart';
import '../presentation/controllers/clipboard_state.dart';
import 'clipboard_service.dart';
import 'datasources/clipboard_bridge.dart';
import 'datasources/clipboard_local_datasource.dart';
import 'repositories/clipboard_repository_impl.dart';

/// Dependency injection for the clipboard feature.

final clipboardBridgeProvider = Provider<ClipboardBridge>(
  (ref) => MethodChannelClipboardBridge(),
);

final clipboardServiceProvider = Provider<ClipboardService>(
  (ref) => ClipboardService(ref.watch(clipboardBridgeProvider)),
);

final clipboardLocalDataSourceProvider = Provider<ClipboardLocalDataSource>(
  (ref) => ClipboardLocalDataSource(ref.watch(clipboardStoreProvider)),
);

final clipboardRepositoryProvider = Provider<ClipboardRepository>(
  (ref) => ClipboardRepositoryImpl(
    socketManager: ref.watch(socketManagerProvider),
    clipboardService: ref.watch(clipboardServiceProvider),
    localDataSource: ref.watch(clipboardLocalDataSourceProvider),
  ),
);

final clipboardControllerProvider =
    NotifierProvider<ClipboardController, ClipboardState>(
  ClipboardController.new,
);
