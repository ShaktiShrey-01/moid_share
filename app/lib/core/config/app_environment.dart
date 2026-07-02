/// Build flavor for Moid-Share.
///
/// Selected at build time via `--dart-define=ENV=dev|staging|prod`.
enum Flavor { dev, staging, prod }

/// Immutable, compile-time application configuration.
///
/// Values are injected with `--dart-define` so that no environment-specific
/// URLs or keys live in source control. Reasonable localhost defaults are used
/// for `dev` so a fresh checkout runs against a local backend with zero flags.
///
/// Example:
/// ```
/// flutter run --dart-define=ENV=prod \
///   --dart-define=API_BASE_URL=https://api.moidshare.com \
///   --dart-define=SOCKET_URL=wss://api.moidshare.com
/// ```
///
/// This is a plain singleton (not a provider) because configuration is fixed
/// for the entire process lifetime and is needed before the provider container
/// exists (e.g. during [bootstrap]).
final class AppEnvironment {
  const AppEnvironment._({
    required this.flavor,
    required this.apiBaseUrl,
    required this.socketUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableNetworkLogging,
    required this.googleServerClientId,
  });

  /// The active configuration for this build. Initialized once in [bootstrap].
  static late final AppEnvironment current;

  final Flavor flavor;

  /// REST API base URL, e.g. `https://api.moidshare.com/api/v1`.
  final String apiBaseUrl;

  /// Socket.IO / WebSocket endpoint for realtime device + clipboard events.
  final String socketUrl;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Whether to log HTTP traffic (never enable in `prod`).
  final bool enableNetworkLogging;

  /// Google OAuth **web/server** client id used to obtain an ID token whose
  /// audience matches the backend. Empty disables Google sign-in on the client.
  final String googleServerClientId;

  bool get isProd => flavor == Flavor.prod;
  bool get isDev => flavor == Flavor.dev;

  /// Reads configuration from `--dart-define` values. Called exactly once.
  factory AppEnvironment.fromEnvironment() {
    const rawEnv = String.fromEnvironment('ENV', defaultValue: 'dev');
    final flavor = switch (rawEnv) {
      'prod' => Flavor.prod,
      'staging' => Flavor.staging,
      _ => Flavor.dev,
    };

    // Android emulator reaches the host machine at 10.0.2.2, not localhost.
    const defaultDevApi = 'http://10.0.2.2:4000/api/v1';
    const defaultDevSocket = 'http://10.0.2.2:4000';

    return AppEnvironment._(
      flavor: flavor,
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: defaultDevApi,
      ),
      socketUrl: const String.fromEnvironment(
        'SOCKET_URL',
        defaultValue: defaultDevSocket,
      ),
      connectTimeout: const Duration(
        milliseconds: int.fromEnvironment(
          'CONNECT_TIMEOUT_MS',
          defaultValue: 15000,
        ),
      ),
      receiveTimeout: const Duration(
        milliseconds: int.fromEnvironment(
          'RECEIVE_TIMEOUT_MS',
          defaultValue: 20000,
        ),
      ),
      enableNetworkLogging:
          flavor != Flavor.prod, // logging off in production by default
      googleServerClientId: const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: '',
      ),
    );
  }
}
