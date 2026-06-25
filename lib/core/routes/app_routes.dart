import 'package:flutter/material.dart';
import 'package:contact_navigator/features/onboarding/splash_screen.dart';
import 'package:contact_navigator/features/contacts/contacts_page.dart';

// كلاس إدارة مسارات التطبيق والتوجيه بين الشاشات المختلفة
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';

  // توليد وتحديد المسار المناسب بناءً على اسم المسار المرسل
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
      case home:
        return MaterialPageRoute(builder: (_) => const ContactsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
