import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:uuid/uuid.dart';

// كلاس يمثل فئة أو تصنيف لجهات الاتصال ويحتوي على عدد جهات الاتصال المنتمية له
class Category {
  final String id;
  final String name;
  int contactCount;

  Category({
    required this.id,
    required this.name,
    this.contactCount = 0,
  });
}

// واجهة خدمة إدارة تصنيفات ومجموعات جهات الاتصال محلياً
abstract class IGroupService {
  // تدفق الأحداث لمعرفة متى تتغير المجموعات
  Stream<void> get onGroupsChanged;

  // جلب كافة المجموعات المسجلة
  Future<List<Category>> getGroups({bool withContactCount = true});

  // إنشاء مجموعة جديدة بالاسم المحدد
  Future<Category> createGroup(String name);

  // حذف مجموعة محددة باستخدام معرّفها
  Future<void> deleteGroup(String groupId);

  // جلب جهات الاتصال التي تنتمي إلى مجموعة معينة
  Future<List<Contact>> getContactsInGroup(String groupId, {List<Contact>? allContacts});

  // إضافة جهة اتصال معينة إلى مجموعة محددة
  Future<void> addContactToGroup(String contactId, String groupId);

  // إزالة جهة اتصال معينة من مجموعة محددة
  Future<void> removeContactFromGroup(String contactId, String groupId);

  // إزالة جهة اتصال معينة من كافة المجموعات المسجلة
  Future<void> removeContactFromAllGroups(String contactId);

  // تعديل اسم مجموعة حالية
  Future<void> updateGroup(String groupId, String newName);
}

// تنفيذ خدمة إدارة مجموعات جهات الاتصال محلياً بالاعتماد على SharedPreferences لحفظ البيانات
class GroupService implements IGroupService {
  static const String _groupsKey = 'local_contact_groups';
  static const String _groupMappingKey = 'local_group_mapping';
  final SharedPreferences _prefs;
  final _changeController = StreamController<void>.broadcast();

  GroupService(this._prefs);

  @override
  Stream<void> get onGroupsChanged => _changeController.stream;

  // إرسال تنبيه للمستمعين عند حدوث تغيير في المجموعات
  void _notifyListeners() => _changeController.add(null);

  // قراءة خريطة المجموعات المخزنة محلياً
  Future<Map<String, String>> _loadGroupsMap() async {
    final str = _prefs.getString(_groupsKey);
    if (str == null) return {};
    return Map<String, String>.from(jsonDecode(str));
  }

  // قراءة خريطة العلاقات بين جهات الاتصال والمجموعات
  Future<Map<String, List<String>>> _loadMapping() async {
    final str = _prefs.getString(_groupMappingKey);
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  // حفظ خريطة المجموعات محلياً
  Future<void> _saveGroupsMap(Map<String, String> groups) async {
    await _prefs.setString(_groupsKey, jsonEncode(groups));
  }

  // حفظ خريطة العلاقات بين جهات الاتصال والمجموعات محلياً
  Future<void> _saveMapping(Map<String, List<String>> mapping) async {
    await _prefs.setString(_groupMappingKey, jsonEncode(mapping));
  }

  // جلب كافة المجموعات مع خيار حساب عدد الأعضاء في كل منها
  @override
  Future<List<Category>> getGroups({bool withContactCount = true}) async {
    final groupsMap = await _loadGroupsMap();
    final mapping = withContactCount ? await _loadMapping() : <String, List<String>>{};
    
    return groupsMap.entries.map((e) {
      return Category(
        id: e.key,
        name: e.value,
        contactCount: mapping[e.key]?.length ?? 0,
      );
    }).toList();
  }

  // إنشاء مجموعة جديدة وتوليد معرف فريد لها وحفظ التغييرات
  @override
  Future<Category> createGroup(String name) async {
    final groupsMap = await _loadGroupsMap();
    final id = const Uuid().v4();
    groupsMap[id] = name;
    await _saveGroupsMap(groupsMap);
    _notifyListeners();
    return Category(id: id, name: name);
  }

  // حذف مجموعة محددة والتأثيرات المرتبطة بها في خرائط العلاقات
  @override
  Future<void> deleteGroup(String groupId) async {
    final groupsMap = await _loadGroupsMap();
    groupsMap.remove(groupId);
    await _saveGroupsMap(groupsMap);

    final mapping = await _loadMapping();
    mapping.remove(groupId);
    await _saveMapping(mapping);
    _notifyListeners();
  }

  // جلب قائمة جهات الاتصال التي تنتمي إلى مجموعة معينة بالاعتماد على العلاقات المخزنة
  @override
  Future<List<Contact>> getContactsInGroup(String groupId, {List<Contact>? allContacts}) async {
    final mapping = await _loadMapping();
    final contactIds = mapping[groupId] ?? [];
    
    if (contactIds.isEmpty) return [];

    final List<Contact> contactsToSearch = allContacts ?? await FlutterContacts.getAll(properties: ContactProperties.all);
    return contactsToSearch.where((c) => contactIds.contains(c.id)).toList();
  }

  // إضافة جهة اتصال لمجموعة معينة وحفظ التغيير
  @override
  Future<void> addContactToGroup(String contactId, String groupId) async {
    final mapping = await _loadMapping();
    final list = mapping[groupId] ?? [];
    if (!list.contains(contactId)) {
      list.add(contactId);
      mapping[groupId] = list;
      await _saveMapping(mapping);
      _notifyListeners();
    }
  }

  // إزالة جهة اتصال من مجموعة معينة وحفظ التغيير
  @override
  Future<void> removeContactFromGroup(String contactId, String groupId) async {
    final mapping = await _loadMapping();
    final list = mapping[groupId] ?? [];
    if (list.contains(contactId)) {
      list.remove(contactId);
      mapping[groupId] = list;
      await _saveMapping(mapping);
      _notifyListeners();
    }
  }

  // إزالة جهة اتصال من كافة المجموعات التي تنتمي إليها
  @override
  Future<void> removeContactFromAllGroups(String contactId) async {
    final mapping = await _loadMapping();
    bool changed = false;
    mapping.forEach((groupId, list) {
      if (list.contains(contactId)) {
        list.remove(contactId);
        changed = true;
      }
    });
    if (changed) {
      await _saveMapping(mapping);
      _notifyListeners();
    }
  }

  // تحديث اسم مجموعة حالية وحفظ التغييرات
  @override
  Future<void> updateGroup(String groupId, String newName) async {
    final groupsMap = await _loadGroupsMap();
    if (groupsMap.containsKey(groupId)) {
      groupsMap[groupId] = newName;
      await _saveGroupsMap(groupsMap);
      _notifyListeners();
    }
  }

  // إغلاق متحكم تدفق التغييرات
  void dispose() {
    _changeController.close();
  }
}
