// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Moid-Share';

  @override
  String get homeWelcome => 'Welcome';

  @override
  String homeWelcomeNamed(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeSubtitle => 'Manage your devices and connections.';

  @override
  String get cardDevicesTitle => 'Registered devices';

  @override
  String get cardDevicesSubtitle => 'View and manage your devices';

  @override
  String get cardPairTitle => 'Pair a device';

  @override
  String get cardPairSubtitle => 'Link this device with another by code';

  @override
  String get cardNearbyTitle => 'Nearby devices';

  @override
  String get cardNearbySubtitle => 'Discover devices on your network';

  @override
  String get cardClipboardTitle => 'Clipboard sync';

  @override
  String get cardClipboardSubtitle => 'Share clipboard across your devices';

  @override
  String get cardTransfersTitle => 'Transfers';

  @override
  String get cardTransfersSubtitle => 'Send files and view transfer history';

  @override
  String get actionSettings => 'Settings';

  @override
  String get actionSignOut => 'Sign out';
}
