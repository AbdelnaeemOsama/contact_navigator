import 'package:flutter/material.dart';
import 'package:contact_navigator/app_theme.dart';
import 'package:contact_navigator/splash_screen.dart';

void main() {
  runApp(const ContactNavigatorApp());
}

class ContactNavigatorApp extends StatelessWidget {
  const ContactNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      theme: ThemeData(
        fontFamily: AppFonts.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
