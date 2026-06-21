import 'package:mocktail/mocktail.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/services/contact_service.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'package:contact_navigator/core/services/settings_service.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'dart:async';
import 'dart:typed_data';

class MockContactService extends Mock implements IContactService {}

class MockGroupService extends Mock implements IGroupService {}

class MockSettingsService extends Mock implements SettingsService {
  MockSettingsService() : super();

  final Map<String, dynamic> _store = {
    'sort_order': 0,
    'name_format': 0,
    'voice_enabled': false,
    'favorites_ids': <String>[],
  };

  @override
  ContactSortOrder getSortOrder() => ContactSortOrder.values[_store['sort_order'] as int];

  @override
  Future<void> setSortOrder(ContactSortOrder order) async {
    _store['sort_order'] = order.index;
  }

  @override
  ContactNameFormat getNameFormat() => ContactNameFormat.values[_store['name_format'] as int];

  @override
  Future<void> setNameFormat(ContactNameFormat format) async {
    _store['name_format'] = format.index;
  }

  @override
  bool isVoiceEnabled() => _store['voice_enabled'] as bool;

  @override
  Future<void> setVoiceEnabled(bool enabled) async {
    _store['voice_enabled'] = enabled;
  }

  @override
  List<String> getFavoriteIds() => List<String>.from(_store['favorites_ids'] as List);

  @override
  Future<void> setFavoriteIds(List<String> ids) async {
    _store['favorites_ids'] = ids;
  }

  @override
  bool isFavorite(String contactId) => getFavoriteIds().contains(contactId);

  @override
  Future<void> toggleFavorite(String contactId) async {
    final list = getFavoriteIds().toList();
    if (list.contains(contactId)) {
      list.remove(contactId);
    } else {
      list.add(contactId);
    }
    setFavoriteIds(list);
  }
}

Contact makeContact({
  String id = '1',
  String? firstName,
  String? lastName,
  String displayName = 'Test User',
  List<String>? phones,
}) {
  return Contact(
    id: id,
    name: Name(first: firstName, last: lastName),
    displayName: displayName,
    phones: (phones ?? ['+1234567890']).map((n) => Phone(number: n)).toList(),
  );
}
