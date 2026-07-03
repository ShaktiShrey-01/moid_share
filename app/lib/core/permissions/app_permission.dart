/// App-level permissions the features request, kept independent of any plugin.
///
/// Mapping to the underlying OS permission lives in the service implementation,
/// so features and UI depend only on this platform-neutral enum. macOS will map
/// the same set to its own prompts later.
enum AppPermission {
  /// Post notifications (Android 13+ runtime prompt).
  notifications,

  /// Read files chosen for sending / write received files.
  storage,

  /// Local network / nearby-device discovery.
  nearbyDevices,
}

/// Outcome of a permission query or request.
enum PermissionOutcome {
  granted,
  denied,

  /// Denied with "don't ask again" — the caller must send the user to settings.
  permanentlyDenied,

  /// Not applicable on this platform/OS version (treated as usable).
  notApplicable,
}

extension PermissionOutcomeX on PermissionOutcome {
  /// True when the app may proceed (granted or the OS doesn't gate it).
  bool get isUsable =>
      this == PermissionOutcome.granted ||
      this == PermissionOutcome.notApplicable;
}
