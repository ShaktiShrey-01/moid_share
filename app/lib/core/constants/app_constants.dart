/// App-wide, environment-independent constants.
///
/// Anything that varies per environment belongs in [AppEnvironment], not here.
abstract final class AppConstants {
  const AppConstants._();

  /// Display name shown in UI chrome.
  static const String appName = 'Moid-Share';

  /// Namespace for platform-channel identifiers and storage keys.
  static const String bundleNamespace = 'com.moidshare';

  /// Default API request page size.
  static const int defaultPageSize = 20;

  /// Debounce used for search inputs and rapid UI events.
  static const Duration inputDebounce = Duration(milliseconds: 300);
}

/// Keys used with secure storage. Centralized to avoid stringly-typed drift.
abstract final class SecureStorageKeys {
  const SecureStorageKeys._();

  static const String accessToken = 'auth.access_token';
  static const String refreshToken = 'auth.refresh_token';
  static const String deviceId = 'device.id';
}

/// Hive box names for non-sensitive local cache.
abstract final class HiveBoxes {
  const HiveBoxes._();

  static const String settings = 'settings_box';
  static const String devices = 'devices_box';
  static const String transferHistory = 'transfer_history_box';
  static const String clipboard = 'clipboard_box';
}

/// Asset paths. Keeping these in one place prevents typos at call sites.
abstract final class AssetPaths {
  const AssetPaths._();

  static const String _animations = 'assets/animations';
  static const String _images = 'assets/images';

  static const String emptyBoxAnimation = '$_animations/empty_box.json';
  static const String loadingAnimation = '$_animations/loading.json';
  static const String logo = '$_images/logo.png';
}
