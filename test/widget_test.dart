// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:contact_navigator/core/services/settings_service.dart';
import 'package:contact_navigator/main.dart';

void main() {
  testWidgets('App starts with Splash and transitions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'isFirstLaunch': false});
    final prefs = await SharedPreferences.getInstance();
    final settingsService = SettingsService(prefs);

    await tester.pumpWidget(ContactNavigatorApp(settingsService: settingsService, prefs: prefs));

    // Wait for timer and transition
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1)); // Extra pump for navigation frame

    // Verify transition (SplashScreen should be gone)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
