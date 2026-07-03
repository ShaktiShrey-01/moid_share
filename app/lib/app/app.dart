import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../l10n/app_localizations.dart';

/// Root widget: wires the router and the light/dark themes into
/// [MaterialApp.router].
///
/// Intentionally thin — all configuration comes from providers so this widget
/// has a single responsibility: compose the app shell.
class MoidShareApp extends ConsumerWidget {
  const MoidShareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
