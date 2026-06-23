import 'package:flutter/material.dart';

// فئة مساعدة للتعامل مع النصوص وتحديد اتجاهها ومحاذاتها تلقائياً (عربي / إنجليزي)
class TextUtils {
  /// Returns true if the string contains Arabic characters.
  // التحقق مما إذا كان النص يحتوي على أحرف عربية
  static bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  /// Returns the appropriate text direction for a given string.
  // الحصول على اتجاه النص المناسب (يمين لليسار أو العكس) بناءً على اللغة
  static TextDirection getTextDirection(String text) {
    return isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Returns the appropriate text alignment for a given string.
  // الحصول على محاذاة النص المناسبة (يمين أو يسار) بناءً على اللغة
  static TextAlign getTextAlign(String text) {
    return isArabic(text) ? TextAlign.right : TextAlign.left;
  }
}
