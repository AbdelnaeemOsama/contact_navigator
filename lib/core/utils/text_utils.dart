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

  /// Removes Arabic diacritics (tashkeel).
  static String removeDiacritics(String text) {
    final diacriticsRegex = RegExp(r'[\u064B-\u0652]');
    return text.replaceAll(diacriticsRegex, '');
  }

  /// Strips non-Arabic/alphanumeric symbols like ★, @, •, etc.
  static String stripSymbols(String text) {
    final symbolRegex = RegExp(r'[^a-zA-Z0-9\s\u0621-\u064A\u0660-\u0669\u0671-\u06D3]');
    return text.replaceAll(symbolRegex, '');
  }

  /// Normalises a string by removing diacritics, stripping symbols, lowercasing, and cleaning whitespace.
  static String normalise(String text) {
    final cleanDiacritics = removeDiacritics(text);
    final cleanSymbols = stripSymbols(cleanDiacritics);
    return cleanSymbols.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Builds a display name fallback if displayName is null/empty.
  static String buildDisplayName(String? displayName, String? firstName, String? lastName) {
    final dn = (displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;

    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    if (fn.isNotEmpty || ln.isNotEmpty) {
      return '$fn $ln'.trim();
    }
    return 'Unknown';
  }
}
