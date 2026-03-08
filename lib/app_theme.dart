import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFFF5F5F5);
  static const cardGrey = Color(0xFFE0E0E0);
  static const primaryBlue = Color(0xFF0070C9);
  static const textBlue = Color(0xFF004080);
  static const dialogBackground = Color(0xFFE7EFF7);
}

class AppFonts {
  AppFonts._();

  static const primary = 'Roboto';
}

class AppTextStyles {
  AppTextStyles._();

  static const title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textBlue,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBlue,
    height: 1.4,
  );

  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
