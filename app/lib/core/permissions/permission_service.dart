import 'package:permission_handler/permission_handler.dart' as ph;

import 'app_permission.dart';

/// Requests and inspects runtime permissions.
///
/// Features depend on this abstraction, never on `permission_handler` directly,
/// so the plugin stays swappable and the logic is unit-testable with a fake.
/// The interface speaks in the app's own [AppPermission] / [PermissionOutcome]
/// vocabulary.
abstract interface class PermissionService {
  /// Current status without prompting.
  Future<PermissionOutcome> status(AppPermission permission);

  /// Requests [permission], prompting the user if needed.
  Future<PermissionOutcome> request(AppPermission permission);

  /// Opens the OS app-settings page (for permanently-denied recovery).
  Future<bool> openSettings();
}

/// `permission_handler`-backed implementation.
class PermissionServiceImpl implements PermissionService {
  const PermissionServiceImpl();

  @override
  Future<PermissionOutcome> status(AppPermission permission) async {
    final permissions = _map(permission);
    if (permissions.isEmpty) return PermissionOutcome.notApplicable;
    final statuses = <ph.PermissionStatus>[
      for (final p in permissions) await p.status,
    ];
    return _reduce(statuses);
  }

  @override
  Future<PermissionOutcome> request(AppPermission permission) async {
    final permissions = _map(permission);
    if (permissions.isEmpty) return PermissionOutcome.notApplicable;
    final result = await permissions.request();
    return _reduce(result.values.toList());
  }

  @override
  Future<bool> openSettings() => ph.openAppSettings();

  /// Maps an [AppPermission] to the concrete OS permission(s) to request.
  List<ph.Permission> _map(AppPermission permission) => switch (permission) {
        AppPermission.notifications => [ph.Permission.notification],
        AppPermission.storage => [ph.Permission.storage],
        AppPermission.nearbyDevices => [ph.Permission.nearbyWifiDevices],
      };

  /// Collapses multiple statuses into one outcome (worst case wins).
  PermissionOutcome _reduce(List<ph.PermissionStatus> statuses) {
    if (statuses.isEmpty) return PermissionOutcome.notApplicable;
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return PermissionOutcome.permanentlyDenied;
    }
    if (statuses.any((s) => s.isDenied || s.isRestricted)) {
      return PermissionOutcome.denied;
    }
    return PermissionOutcome.granted;
  }
}
