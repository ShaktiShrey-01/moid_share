import 'package:flutter/material.dart';

/// Maps a device platform string to a representative icon.
IconData platformIcon(String platform) => switch (platform) {
      'android' => Icons.phone_android,
      'ios' => Icons.phone_iphone,
      'macos' => Icons.laptop_mac,
      'windows' => Icons.laptop_windows,
      'linux' => Icons.laptop,
      'web' => Icons.public,
      _ => Icons.devices_other,
    };
