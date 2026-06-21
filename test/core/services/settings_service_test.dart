import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contact_navigator/core/services/settings_service.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';

void main() {
  late SettingsService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // We need to await getInstance because the mock needs to be initialized
  });

  group('SettingsService', () {
    test('default sort order is firstName', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      expect(service.getSortOrder(), ContactSortOrder.firstName);
    });

    test('setSortOrder persists the value', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      await service.setSortOrder(ContactSortOrder.lastName);
      expect(service.getSortOrder(), ContactSortOrder.lastName);
    });

    test('default name format is firstLast', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      expect(service.getNameFormat(), ContactNameFormat.firstLast);
    });

    test('setNameFormat persists the value', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      await service.setNameFormat(ContactNameFormat.lastFirst);
      expect(service.getNameFormat(), ContactNameFormat.lastFirst);
    });

    test('voice is disabled by default', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      expect(service.isVoiceEnabled(), false);
    });

    test('setVoiceEnabled toggles the value', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      await service.setVoiceEnabled(true);
      expect(service.isVoiceEnabled(), true);
      await service.setVoiceEnabled(false);
      expect(service.isVoiceEnabled(), false);
    });

    test('favoriteIds is empty by default', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      expect(service.getFavoriteIds(), []);
    });

    test('isFavorite returns false for unknown id', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      expect(service.isFavorite('nonexistent'), false);
    });

    test('toggleFavorite adds and removes ids', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      await service.toggleFavorite('abc');
      expect(service.isFavorite('abc'), true);
      expect(service.getFavoriteIds(), ['abc']);

      await service.toggleFavorite('abc');
      expect(service.isFavorite('abc'), false);
      expect(service.getFavoriteIds(), []);
    });

    test('multiple favorites can be added', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SettingsService(prefs);
      await service.toggleFavorite('a');
      await service.toggleFavorite('b');
      await service.toggleFavorite('c');
      expect(service.getFavoriteIds(), ['a', 'b', 'c']);
    });
  });
}
