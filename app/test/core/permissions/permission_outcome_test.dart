import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/core/permissions/app_permission.dart';

void main() {
  test('granted and notApplicable are usable; denied variants are not', () {
    expect(PermissionOutcome.granted.isUsable, isTrue);
    expect(PermissionOutcome.notApplicable.isUsable, isTrue);
    expect(PermissionOutcome.denied.isUsable, isFalse);
    expect(PermissionOutcome.permanentlyDenied.isUsable, isFalse);
  });
}
