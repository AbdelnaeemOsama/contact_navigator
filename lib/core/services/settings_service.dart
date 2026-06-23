import 'package:shared_preferences/shared_preferences.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';

// خدمة إدارة وحفظ إعدادات التطبيق وتفضيلات المستخدم محلياً
class SettingsService {
  static const String _keySortOrder = 'sort_order';
  static const String _keyNameFormat = 'name_format';
  static const String _keyVoiceEnabled = 'voice_enabled';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // تهيئة الخدمة وإنشاء نسخة من SharedPreferences
  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // الحصول على ترتيب الفرز الحالي لجهات الاتصال
  ContactSortOrder getSortOrder() {
    final index = _prefs.getInt(_keySortOrder) ?? 0;
    return ContactSortOrder.values[index];
  }

  // تعيين خيار ترتيب فرز جهات الاتصال وحفظه
  Future<void> setSortOrder(ContactSortOrder order) async {
    await _prefs.setInt(_keySortOrder, order.index);
  }

  // الحصول على صيغة عرض الاسم لجهات الاتصال
  ContactNameFormat getNameFormat() {
    final index = _prefs.getInt(_keyNameFormat) ?? 0;
    return ContactNameFormat.values[index];
  }

  // تعيين صيغة عرض الاسم لجهات الاتصال وحفظها
  Future<void> setNameFormat(ContactNameFormat format) async {
    await _prefs.setInt(_keyNameFormat, format.index);
  }

  // التحقق مما إذا كان المساعد الصوتي مفعلاً
  bool isVoiceEnabled() {
    return _prefs.getBool(_keyVoiceEnabled) ?? false;
  }

  // تفعيل أو تعطيل خيار المساعد الصوتي
  Future<void> setVoiceEnabled(bool enabled) async {
    await _prefs.setBool(_keyVoiceEnabled, enabled);
  }

  static const String _keyFavorites = 'favorites_ids';

  // جلب قائمة المعرفات الفريدة لجهات الاتصال المفضلة
  List<String> getFavoriteIds() {
    return _prefs.getStringList(_keyFavorites) ?? [];
  }

  // تعيين وحفظ قائمة المعرفات الفريدة للمفضلة
  Future<void> setFavoriteIds(List<String> ids) async {
    await _prefs.setStringList(_keyFavorites, ids);
  }

  // التحقق مما إذا كانت جهة الاتصال مضافة للمفضلة
  bool isFavorite(String contactId) {
    return getFavoriteIds().contains(contactId);
  }

  // تبديل حالة المفضلة لجهة اتصال معينة (إضافة أو إزالة)
  Future<void> toggleFavorite(String contactId) async {
    final list = getFavoriteIds().toList();
    if (list.contains(contactId)) {
      list.remove(contactId);
    } else {
      list.add(contactId);
    }
    await setFavoriteIds(list);
  }
}
