import 'package:shared_preferences/shared_preferences.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';

class SettingsService {
  static const String _keySortOrder = 'sort_order';
  static const String _keyNameFormat = 'name_format';
  static const String _keyVoiceEnabled = 'voice_enabled';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  ContactSortOrder getSortOrder() {
    final index = _prefs.getInt(_keySortOrder) ?? 0;
    return ContactSortOrder.values[index];
  }

  Future<void> setSortOrder(ContactSortOrder order) async {
    await _prefs.setInt(_keySortOrder, order.index);
  }

  ContactNameFormat getNameFormat() {
    final index = _prefs.getInt(_keyNameFormat) ?? 0;
    return ContactNameFormat.values[index];
  }

  Future<void> setNameFormat(ContactNameFormat format) async {
    await _prefs.setInt(_keyNameFormat, format.index);
  }

  bool isVoiceEnabled() {
    return _prefs.getBool(_keyVoiceEnabled) ?? false;
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    await _prefs.setBool(_keyVoiceEnabled, enabled);
  }
}
