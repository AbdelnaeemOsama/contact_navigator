import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:flutter/foundation.dart';

// واجهة خدمة إدارة جهات الاتصال لتحديد العمليات المدعومة
abstract class IContactService {
  // طلب صلاحيات قراءة وكتابة جهات الاتصال من النظام
  Future<bool> requestPermission();

  // جلب قائمة جهات الاتصال مع إمكانية الفلترة أو التصفية حسب المجموعة
  Future<List<Contact>> getContacts({
    bool withProperties = true,
    bool withPhoto = true,
    String? query,
    String? groupId,
  });

  // إنشاء جهة اتصال جديدة وحفظها في النظام مع إمكانية ربطها بمجموعة
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

  // تحديث بيانات جهة اتصال موجودة
  Future<void> updateContact(Contact contact);

  // حذف جهة اتصال نهائياً باستخدام معرفها الفريد
  Future<void> deleteContact(String id);

  // إضافة قائمة من جهات الاتصال إلى مجموعة معينة
  Future<void> addToGroup(List<String> contactIds, String groupId);

  // تصدير بيانات جهة الاتصال إلى صيغة ملف VCard نصي
  Future<String> exportToVCard(Contact contact);

  // فتح جهة الاتصال في تطبيق جهات الاتصال الافتراضي للنظام
  Future<void> showNativeContact(String id);

  // فتح رابط موقع جغرافي في متصفح خارجي أو تطبيق خرائط
  Future<void> launchLocation(String url);

  // جلب الملف الشخصي الخاص بالمستخدم الحالي (الملف المسمى "أنا")
  Future<Contact?> getProfile();

  // تحديث بيانات الملف الشخصي الخاص بالمستخدم
  Future<void> updateProfile(Contact contact);

  // الحصول على رقم الهاتف الخاص ببطاقة SIM للمستخدم
  Future<String?> getSimNumber();
}

// تنفيذ واجهة خدمة إدارة جهات الاتصال بالاعتماد على حزمة flutter_contacts
class ContactService implements IContactService {
  // طلب صلاحيات الوصول لجهات الاتصال من نظام التشغيل
  @override
  Future<bool> requestPermission() async {
    final status = await FlutterContacts.permissions.request(
      PermissionType.readWrite,
    );
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  // جلب جهات الاتصال وتفاصيلها وصورها مع خيارات التصفية والبحث
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
      properties: withProperties
          ? (withPhoto
              ? ContactProperties.all
              : ContactProperties.allProperties)
          : ContactProperties.none,
      filter: filter,
    );
  }

  // إنشاء جهة اتصال جديدة وحفظها في النظام مع إضافة إمكانية المحاولة المتكررة لإدراجها بمجموعة
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

  // تحديث بيانات جهة الاتصال بالنظام مع دمج التغييرات مع البيانات المخزنة محلياً لتفادي فقدان المعرفات الفريدة
  @override
  Future<void> updateContact(Contact contact) async {
    final id = contact.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Cannot update contact without an ID');
    }
    // Re-fetch the full contact with all system-level identifiers
    // This is the pattern used in the official examples for reliable Android updates
    final full = await FlutterContacts.get(
      id,
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

  // حذف جهة الاتصال من الجهاز
  @override
  Future<void> deleteContact(String id) async {
    await FlutterContacts.delete(id);
  }

  // ربط مجموعة من المعرفات الفريدة لجهات الاتصال بمجموعة/تصنيف معين
  @override
  Future<void> addToGroup(List<String> contactIds, String groupId) async {
    await FlutterContacts.groups.addContacts(
      groupId: groupId,
      contactIds: contactIds,
    );
  }

  // تصدير جهة الاتصال بصيغة vCard النصية
  @override
  Future<String> exportToVCard(Contact contact) async {
    return FlutterContacts.vCard.export(contact);
  }

  // استعراض جهة الاتصال داخل تطبيق العرض الافتراضي للنظام
  @override
  Future<void> showNativeContact(String id) async {
    await FlutterContacts.native.showViewer(id);
  }

  // فتح رابط موقع جغرافي باستخدام التطبيق الخارجي المناسب
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

  // جلب الملف الشخصي الخاص بالمستخدم الأساسي للجهاز
  @override
  Future<Contact?> getProfile() async {
    return await FlutterContacts.profile.get(properties: ContactProperties.all);
  }

  // تحديث الملف الشخصي الخاص بالمستخدم
  @override
  Future<void> updateProfile(Contact contact) async {
    // Note: Profile update support varies by device and platform permissions
    // On some Android devices, the "Me" card is read-only or managed by Google Account
    await FlutterContacts.update(contact);
  }

  // قراءة رقم الهاتف للشريحة المثبتة بالجهاز عبر مكتبة mobile_number
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
