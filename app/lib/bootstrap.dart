import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/logging/app_logger.dart';
import 'core/storage/key_value_store.dart';
import 'core/storage/storage_initializer.dart';
import 'core/storage/storage_providers.dart';
import 'core/network/auth_token_store.dart';
import 'core/session/auth_status.dart';
import 'features/auth/data/auth_providers.dart';

/// Composition root.
///
/// Owns the exact startup order that the rest of the app assumes:
///   1. bind the Flutter engine,
///   2. load compile-time configuration ([AppEnvironment]),
///   3. open persistence ([StorageInitializer]),
///   4. install global error handlers, and
///   5. run the app inside a guarded zone with the opened storage injected
///      into the provider graph.
///
/// Keeping this in one place means `main.dart` stays a one-liner and startup is
/// never duplicated or reordered by accident.
Future<void> bootstrap() async {
  // Run everything inside a guarded zone so *any* async error is captured.
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Configuration (must exist before any provider reads it).
      AppEnvironment.current = AppEnvironment.fromEnvironment();

      final logger = ConsoleAppLogger();

      // 2. Persistence.
      final boxes = await const StorageInitializer().initialize();

      // 3. Framework-level error handling.
      _installErrorHandlers(logger);

      // 4. Run, injecting opened Hive boxes into the DI graph.
      runApp(
        ProviderScope(
          overrides: [
            settingsStoreProvider
                .overrideWithValue(HiveKeyValueStore(boxes.settings)),
            devicesStoreProvider
                .overrideWithValue(HiveKeyValueStore(boxes.devices)),
            transferHistoryStoreProvider
                .overrideWithValue(HiveKeyValueStore(boxes.transferHistory)),
            // Plug the auth feature into the core seams:
            authTokenStoreProvider
                .overrideWith((ref) => ref.watch(apiAuthTokenStoreProvider)),
            authStatusProvider.overrideWith(
              (ref) => ref.watch(
                authControllerProvider.select((s) => s.status),
              ),
            ),
          ],
          child: const MoidShareApp(),
        ),
      );
    },
    (error, stack) {
      // Last line of defense for uncaught async errors.
      ConsoleAppLogger().error(
        'Uncaught zone error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

/// Routes Flutter framework and platform-dispatcher errors through [logger].
void _installErrorHandlers(AppLogger logger) {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    logger.error(
      'FlutterError: ${details.summary}',
      error: details.exception,
      stackTrace: details.stack,
    );
    previousOnError?.call(details);
  };

  // Errors that escape the Flutter framework (e.g. in platform channels).
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('PlatformDispatcher error',
        error: error, stackTrace: stack);
    return true; // handled — prevents a hard crash
  };

  // In debug, show a styled error widget instead of the raw grey box.
  if (kDebugMode) {
    ErrorWidget.builder = (details) => Material(
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
  }
}
