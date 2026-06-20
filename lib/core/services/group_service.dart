import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:uuid/uuid.dart';

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

abstract class IGroupService {
  Stream<void> get onGroupsChanged;
  Future<List<Category>> getGroups({bool withContactCount = true});
  Future<Category> createGroup(String name);
  Future<void> deleteGroup(String groupId);
  Future<List<Contact>> getContactsInGroup(String groupId, {List<Contact>? allContacts});
  Future<void> addContactToGroup(String contactId, String groupId);
  Future<void> removeContactFromGroup(String contactId, String groupId);
  Future<void> removeContactFromAllGroups(String contactId);
  Future<void> updateGroup(String groupId, String newName);
}

class GroupService implements IGroupService {
  static const String _groupsKey = 'local_contact_groups';
  static const String _groupMappingKey = 'local_group_mapping';
  final SharedPreferences _prefs;
  final _changeController = StreamController<void>.broadcast();

  GroupService(this._prefs);

  @override
  Stream<void> get onGroupsChanged => _changeController.stream;

  void _notifyListeners() => _changeController.add(null);

  Future<Map<String, String>> _loadGroupsMap() async {
    final str = _prefs.getString(_groupsKey);
    if (str == null) return {};
    return Map<String, String>.from(jsonDecode(str));
  }

  Future<Map<String, List<String>>> _loadMapping() async {
    final str = _prefs.getString(_groupMappingKey);
    if (str == null) return {};
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  Future<void> _saveGroupsMap(Map<String, String> groups) async {
    await _prefs.setString(_groupsKey, jsonEncode(groups));
  }

  Future<void> _saveMapping(Map<String, List<String>> mapping) async {
    await _prefs.setString(_groupMappingKey, jsonEncode(mapping));
  }

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

  @override
  Future<Category> createGroup(String name) async {
    final groupsMap = await _loadGroupsMap();
    final id = const Uuid().v4();
    groupsMap[id] = name;
    await _saveGroupsMap(groupsMap);
    _notifyListeners();
    return Category(id: id, name: name);
  }

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

  @override
  Future<List<Contact>> getContactsInGroup(String groupId, {List<Contact>? allContacts}) async {
    final mapping = await _loadMapping();
    final contactIds = mapping[groupId] ?? [];
    
    if (contactIds.isEmpty) return [];

    final List<Contact> contactsToSearch = allContacts ?? await FlutterContacts.getAll(properties: ContactProperties.all);
    return contactsToSearch.where((c) => contactIds.contains(c.id)).toList();
  }

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

  @override
  Future<void> updateGroup(String groupId, String newName) async {
    final groupsMap = await _loadGroupsMap();
    if (groupsMap.containsKey(groupId)) {
      groupsMap[groupId] = newName;
      await _saveGroupsMap(groupsMap);
      _notifyListeners();
    }
  }

  void dispose() {
    _changeController.close();
  }
}
