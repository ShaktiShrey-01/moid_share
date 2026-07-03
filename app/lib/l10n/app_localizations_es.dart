// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Moid-Share';

  @override
  String get homeWelcome => 'Bienvenido';

  @override
  String homeWelcomeNamed(String name) {
    return 'Bienvenido, $name';
  }

  @override
  String get homeSubtitle => 'Gestiona tus dispositivos y conexiones.';

  @override
  String get cardDevicesTitle => 'Dispositivos registrados';

  @override
  String get cardDevicesSubtitle => 'Ver y gestionar tus dispositivos';

  @override
  String get cardPairTitle => 'Vincular un dispositivo';

  @override
  String get cardPairSubtitle =>
      'Vincula este dispositivo con otro mediante un código';

  @override
  String get cardNearbyTitle => 'Dispositivos cercanos';

  @override
  String get cardNearbySubtitle => 'Descubre dispositivos en tu red';

  @override
  String get cardClipboardTitle => 'Sincronización del portapapeles';

  @override
  String get cardClipboardSubtitle =>
      'Comparte el portapapeles entre tus dispositivos';

  @override
  String get cardTransfersTitle => 'Transferencias';

  @override
  String get cardTransfersSubtitle => 'Envía archivos y consulta el historial';

  @override
  String get actionSettings => 'Ajustes';

  @override
  String get actionSignOut => 'Cerrar sesión';
}
