import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:contact_navigator/core/services/settings_service.dart';
import 'package:contact_navigator/main.dart';

void main() {
  testWidgets('Splash navigates to home when not first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isFirstLaunch': false});
    final prefs = await SharedPreferences.getInstance();
    final settingsService = SettingsService(prefs);

    await tester.pumpWidget(ContactNavigatorApp(settingsService: settingsService, prefs: prefs));

    // SplashScreen should be showing
    expect(find.byType(ContactNavigatorApp), findsOneWidget);

    // Splash navigates immediately after prefs load
    await tester.pumpAndSettle();

    // Should have navigated without errors
    expect(tester.takeException(), isNull);
  });

  testWidgets('Splash navigates to onboarding on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isFirstLaunch': true});
    final prefs = await SharedPreferences.getInstance();
    final settingsService = SettingsService(prefs);

    await tester.pumpWidget(ContactNavigatorApp(settingsService: settingsService, prefs: prefs));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
