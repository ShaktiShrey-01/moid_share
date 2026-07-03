import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The application name.
  ///
  /// In en, this message translates to:
  /// **'Moid-Share'**
  String get appName;

  /// Home greeting when the user's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcome;

  /// Home greeting with the user's name.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String homeWelcomeNamed(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your devices and connections.'**
  String get homeSubtitle;

  /// No description provided for @cardDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered devices'**
  String get cardDevicesTitle;

  /// No description provided for @cardDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage your devices'**
  String get cardDevicesSubtitle;

  /// No description provided for @cardPairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get cardPairTitle;

  /// No description provided for @cardPairSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Link this device with another by code'**
  String get cardPairSubtitle;

  /// No description provided for @cardNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get cardNearbyTitle;

  /// No description provided for @cardNearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover devices on your network'**
  String get cardNearbySubtitle;

  /// No description provided for @cardClipboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Clipboard sync'**
  String get cardClipboardTitle;

  /// No description provided for @cardClipboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share clipboard across your devices'**
  String get cardClipboardSubtitle;

  /// No description provided for @cardTransfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get cardTransfersTitle;

  /// No description provided for @cardTransfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send files and view transfer history'**
  String get cardTransfersSubtitle;

  /// No description provided for @actionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get actionSettings;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
