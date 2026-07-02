import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../logging/app_logger.dart';

/// Cross-cutting singletons wired through Riverpod (our DI container).
///
/// Feature modules depend on these providers rather than constructing
/// infrastructure themselves, which keeps construction in one place and makes
/// everything trivially overridable in tests via `ProviderScope(overrides:)`.

/// The active [AppEnvironment] for this build.
///
/// Backed by [AppEnvironment.current]; exposed as a provider so tests can
/// override it with a fake environment.
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.current,
);

/// Application-wide logger. Swap the implementation here to route logs to a
/// crash reporter without touching call sites.
final loggerProvider = Provider<AppLogger>(
  (ref) => ConsoleAppLogger(),
);
