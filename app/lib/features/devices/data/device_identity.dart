import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage.dart';

/// Immutable snapshot describing the device the app runs on.
class CurrentDevice {
  const CurrentDevice({
    required this.deviceId,
    required this.name,
    required this.platform,
    this.model,
  });

  final String deviceId;
  final String name;
  final String platform;
  final String? model;
}

/// Resolves a stable device identity.
///
/// The [deviceId] is generated once and persisted in secure storage so it
/// survives restarts (and reinstalls, on platforms that keep the keystore).
/// Human-facing name/model come from `device_info_plus`.
class DeviceIdentity {
  DeviceIdentity(this._secure, [DeviceInfoPlugin? info])
      : _info = info ?? DeviceInfoPlugin();

  final SecureStorage _secure;
  final DeviceInfoPlugin _info;

  Future<CurrentDevice> resolve() async {
    final deviceId = await _resolveId();
    var name = 'My device';
    var platform = 'unknown';
    String? model;

    try {
      if (kIsWeb) {
        platform = 'web';
        name = 'Web browser';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final a = await _info.androidInfo;
            platform = 'android';
            name = a.model;
            model = '${a.manufacturer} ${a.model}';
          case TargetPlatform.iOS:
            final i = await _info.iosInfo;
            platform = 'ios';
            name = i.name;
            model = i.utsname.machine;
          case TargetPlatform.macOS:
            final m = await _info.macOsInfo;
            platform = 'macos';
            name = m.computerName;
            model = m.model;
          case TargetPlatform.windows:
            final w = await _info.windowsInfo;
            platform = 'windows';
            name = w.computerName;
          case TargetPlatform.linux:
            final l = await _info.linuxInfo;
            platform = 'linux';
            name = l.prettyName;
          default:
            break;
        }
      }
    } catch (_) {
      // Fall back to defaults if platform info is unavailable.
    }

    return CurrentDevice(
      deviceId: deviceId,
      name: name.isEmpty ? 'My device' : name,
      platform: platform,
      model: model,
    );
  }

  Future<String> _resolveId() async {
    final existing = await _secure.read(SecureStorageKeys.deviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _generateId();
    await _secure.write(SecureStorageKeys.deviceId, generated);
    return generated;
  }

  /// 32-char hex id from a cryptographically-secure RNG (no extra deps).
  String _generateId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
