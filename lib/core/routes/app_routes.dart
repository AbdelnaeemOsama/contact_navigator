import 'package:flutter/material.dart';
import 'package:contact_navigator/features/onboarding/splash_screen.dart';
import 'package:contact_navigator/features/onboarding/onboarding_screen.dart';
import 'package:contact_navigator/features/permissions/app_permissions_page.dart';
import 'package:contact_navigator/features/permissions/phone_permissions_page.dart';
import 'package:contact_navigator/features/permissions/contacts_permissions_page.dart';
import 'package:contact_navigator/features/permissions/all_permissions_page.dart';
import 'package:contact_navigator/features/contacts/contacts_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String appPermissions = '/permissions/app';
  static const String phonePermissions = '/permissions/phone';
  static const String contactsPermissions = '/permissions/contacts';
  static const String allPermissions = '/permissions/all';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case appPermissions:
        return MaterialPageRoute(builder: (_) => const AppPermissionsPage());
      case phonePermissions:
        return MaterialPageRoute(builder: (_) => const PhonePermissionsPage());
      case contactsPermissions:
        return MaterialPageRoute(builder: (_) => const ContactsPermissionsPage());
      case allPermissions:
        return MaterialPageRoute(builder: (_) => const AllPermissionsPage());
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
