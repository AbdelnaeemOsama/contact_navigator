import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';

void main() {
  group('TextUtils', () {
    group('isArabic', () {
      test('returns true for Arabic text', () {
        expect(TextUtils.isArabic('مرحبا'), isTrue);
        expect(TextUtils.isArabic('العربية'), isTrue);
      });

      test('returns false for English text', () {
        expect(TextUtils.isArabic('Hello'), isFalse);
        expect(TextUtils.isArabic('English'), isFalse);
      });

      test('returns false for mixed text without Arabic', () {
        expect(TextUtils.isArabic('Hello 123'), isFalse);
      });

      test('returns true for mixed text with Arabic', () {
        expect(TextUtils.isArabic('Hello مرحبا'), isTrue);
      });

      test('returns false for empty string', () {
        expect(TextUtils.isArabic(''), isFalse);
      });
    });

    group('getTextDirection', () {
      test('returns rtl for Arabic', () {
        expect(TextUtils.getTextDirection('مرحبا'), TextDirection.rtl);
      });

      test('returns ltr for English', () {
        expect(TextUtils.getTextDirection('Hello'), TextDirection.ltr);
      });
    });

    group('getTextAlign', () {
      test('returns right for Arabic', () {
        expect(TextUtils.getTextAlign('مرحبا'), TextAlign.right);
      });

      test('returns left for English', () {
        expect(TextUtils.getTextAlign('Hello'), TextAlign.left);
      });
    });
  });
}
