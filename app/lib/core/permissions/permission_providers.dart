import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'permission_service.dart';

/// DI for the permission layer. Override in tests with a fake service.
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionServiceImpl(),
);
