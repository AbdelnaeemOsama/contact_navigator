import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class IContactService {
  Future<bool> requestPermission();
  Future<List<Contact>> getContacts({bool withProperties = true, bool withPhoto = true});
}

class ContactService implements IContactService {
  @override
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  @override
  Future<List<Contact>> getContacts({bool withProperties = true, bool withPhoto = true}) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      return [];
    }

    final Set<ContactProperty> properties = {};
    if (withProperties) {
      properties.addAll([
        ContactProperty.name,
        ContactProperty.phone,
        ContactProperty.email,
        ContactProperty.address,
        ContactProperty.organization,
        ContactProperty.note,
      ]);
    }
    if (withPhoto) {
      properties.add(ContactProperty.photoThumbnail);
    }

    return await FlutterContacts.getAll(
      properties: properties.isNotEmpty ? properties : null,
    );
  }
}
