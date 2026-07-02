import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moid_share/app/screens/welcome_screen.dart';
import 'package:moid_share/core/storage/storage_providers.dart';
import 'package:moid_share/core/theme/app_theme.dart';
import 'package:moid_share/core/theme/theme_controller.dart';

import '../../helpers/in_memory_key_value_store.dart';

void main() {
  Widget harness() => ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const WelcomeScreen(),
        ),
      );

  testWidgets('renders brand, tagline and auth actions', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.text('Moid-Share'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('theme toggle flips persisted theme mode', (tester) async {
    await tester.pumpWidget(harness());
    final element = tester.element(find.byType(WelcomeScreen));
    final container = ProviderScope.containerOf(element);

    expect(container.read(themeModeControllerProvider), ThemeMode.system);

    await tester.tap(find.byTooltip('Toggle theme'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
  });

}
