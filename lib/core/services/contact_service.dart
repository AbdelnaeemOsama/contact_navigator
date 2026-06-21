import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:flutter/foundation.dart';

abstract class IContactService {
  Future<bool> requestPermission();
  Future<List<Contact>> getContacts({
    bool withProperties = true,
    bool withPhoto = true,
    String? query,
    String? groupId,
  });
  Future<String> createContact({
    required String firstName,
    required String lastName,
    required List<Phone> phones,
    List<Email> emails = const [],
    List<Address> addresses = const [],
    List<Website> websites = const [],
    String? notes,
    Uint8List? photo,
    String? groupId,
  });
  Future<void> updateContact(Contact contact);
  Future<void> deleteContact(String id);
  Future<void> addToGroup(List<String> contactIds, String groupId);
  Future<String> exportToVCard(Contact contact);
  Future<void> showNativeContact(String id);
  Future<void> launchLocation(String url);
  Future<Contact?> getProfile();
  Future<void> updateProfile(Contact contact);
  Future<String?> getSimNumber();
}

class ContactService implements IContactService {
  @override
  Future<bool> requestPermission() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  @override
  Future<List<Contact>> getContacts({
    bool withProperties = true,
    bool withPhoto = true,
    String? query,
    String? groupId,
  }) async {
    ContactFilter? filter;
    if (groupId != null) {
      filter = ContactFilter.group(groupId);
    } else if (query != null && query.isNotEmpty) {
      filter = ContactFilter.name(query);
    }

    return await FlutterContacts.getAll(
      properties: withProperties ? ContactProperties.all : ContactProperties.none,
      filter: filter,
    );
  }

  @override
  Future<String> createContact({
    required String firstName,
    required String lastName,
    required List<Phone> phones,
    List<Email> emails = const [],
    List<Address> addresses = const [],
    List<Website> websites = const [],
    String? notes,
    Uint8List? photo,
    String? groupId,
  }) async {
    final contact = Contact(
      name: Name(first: firstName, last: lastName),
      phones: phones,
      emails: emails,
      addresses: addresses,
      websites: websites,
      notes: notes != null && notes.isNotEmpty ? [Note(note: notes)] : [],
      photo: photo != null ? Photo(fullSize: photo) : null,
    );

    final createdId = await FlutterContacts.create(contact);

    // Assign to group if provided
    if (groupId != null) {
      // Retry with backoff to handle indexing delay
      int attempts = 0;
      const maxAttempts = 3;
      while (attempts < maxAttempts) {
        try {
          await Future.delayed(Duration(milliseconds: 100 * (attempts + 1)));
          await addToGroup([createdId], groupId);
          break;
        } catch (e) {
          attempts++;
          if (attempts >= maxAttempts) {
            debugPrint(
              'Failed to add contact to group after $maxAttempts attempts: $e',
            );
          }
        }
      }
    }

    return createdId;
  }

  @override
  Future<void> updateContact(Contact contact) async {
    // Re-fetch the full contact with all system-level identifiers
    // This is the pattern used in the official examples for reliable Android updates
    final full = await FlutterContacts.get(
      contact.id!,
      properties: ContactProperties.all,
    );

    if (full != null) {
      // Merge UI changes into the full system contact
      // We explicitly preserve the 'android' metadata which contains system IDs
      final updated = full.copyWith(
        name: contact.name,
        phones: contact.phones,
        emails: contact.emails,
        addresses: contact.addresses,
        websites: contact.websites,
        notes: contact.notes,
        photo: contact.photo,
        // The copyWith on Contact preserves 'android' and 'metadata' by default
        // if we don't pass them, which is what we want here.
      );
      await FlutterContacts.update(updated);
    }
  }

  @override
  Future<void> deleteContact(String id) async {
    await FlutterContacts.delete(id);
  }

  @override
  Future<void> addToGroup(List<String> contactIds, String groupId) async {
    await FlutterContacts.groups.addContacts(
      groupId: groupId,
      contactIds: contactIds,
    );
  }

  @override
  Future<String> exportToVCard(Contact contact) async {
    return FlutterContacts.vCard.export(contact);
  }

  @override
  Future<void> showNativeContact(String id) async {
    await FlutterContacts.native.showViewer(id);
  }

  @override
  Future<void> launchLocation(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Future<Contact?> getProfile() async {
    return await FlutterContacts.profile.get(properties: ContactProperties.all);
  }

  @override
  Future<void> updateProfile(Contact contact) async {
    // Note: Profile update support varies by device and platform permissions
    // On some Android devices, the "Me" card is read-only or managed by Google Account
    await FlutterContacts.update(contact);
  }

  @override
  Future<String?> getSimNumber() async {
    try {
      final bool hasPermission = await MobileNumber.hasPhonePermission;
      if (!hasPermission) {
        await MobileNumber.requestPhonePermission;
      }
      final String? mobileNumber = await MobileNumber.mobileNumber;
      return (mobileNumber == null || mobileNumber.isEmpty)
          ? null
          : mobileNumber;
    } catch (e) {
      debugPrint('Error getting SIM number: $e');
      return null;
    }
  }

}
