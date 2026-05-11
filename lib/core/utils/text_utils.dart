import 'package:flutter/material.dart';

class TextUtils {
  /// Returns true if the string contains Arabic characters.
  static bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  /// Returns the appropriate text direction for a given string.
  static TextDirection getTextDirection(String text) {
    return isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Returns the appropriate text alignment for a given string.
  static TextAlign getTextAlign(String text) {
    return isArabic(text) ? TextAlign.right : TextAlign.left;
  }
}
