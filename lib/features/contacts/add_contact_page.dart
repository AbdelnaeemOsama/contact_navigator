import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/address_page.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:contact_navigator/core/utils/map_utils.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';

// صفحة إضافة وتعديل جهات الاتصال
class AddContactPage extends StatefulWidget {
  final Contact? contactToEdit;
  final String? groupId;
  final String? initialPhone;

  const AddContactPage({super.key, this.contactToEdit, this.groupId, this.initialPhone});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

// نموذج بيانات حقل إدخال الهاتف
class PhoneInput {
  final TextEditingController controller;
  final TextEditingController customLabelController;
  PhoneLabel label;
  PhoneInput({String number = '', String customLabel = '', this.label = PhoneLabel.mobile})
      : controller = TextEditingController(text: number),
        customLabelController = TextEditingController(text: customLabel);
  // تنظيف موارد حقل إدخال الهاتف
  void dispose() {
    controller.dispose();
    customLabelController.dispose();
  }
}

// نموذج بيانات حقل إدخال البريد الإلكتروني
class EmailInput {
  final TextEditingController controller;
  final TextEditingController customLabelController;
  EmailLabel label;
  EmailInput({String address = '', String customLabel = '', this.label = EmailLabel.home})
      : controller = TextEditingController(text: address),
        customLabelController = TextEditingController(text: customLabel);
  // تنظيف موارد حقل إدخال البريد
  void dispose() {
    controller.dispose();
    customLabelController.dispose();
  }
}

// نموذج بيانات حقل إدخال العنوان ورابط الموقع الجغرافي
class AddressInput {
  final TextEditingController controller;
  final TextEditingController linkController;
  AddressInput({String formatted = '', String link = ''})
      : controller = TextEditingController(text: formatted),
        linkController = TextEditingController(text: link);
  // تنظيف موارد حقل إدخال العنوان
  void dispose() {
    controller.dispose();
    linkController.dispose();
  }
}

// حالة صفحة إضافة وتعديل جهات الاتصال
class _AddContactPageState extends State<AddContactPage> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _notesController;
  
  final List<PhoneInput> _phoneInputs = [];
  final List<EmailInput> _emailInputs = [];
  final List<AddressInput> _addressInputs = [];

  String? _selectedGroupId;
  List<Category> _availableGroups = [];

  // تهيئة حقول إدخال جهة الاتصال الحالية عند التعديل أو تجهيز الحقول الفارغة لجهة اتصال جديدة
  @override
  void initState() {
    super.initState();
    final contact = widget.contactToEdit;

    _firstNameController = TextEditingController(
      text: contact?.name?.first ?? '',
    );
    _lastNameController = TextEditingController(
      text: contact?.name?.last ?? '',
    );
    _notesController = TextEditingController(
      text: contact?.notes.isNotEmpty == true
          ? contact!.notes.first.note
          : '',
    );

    if (contact != null) {
      for (final phone in contact.phones) {
        _phoneInputs.add(PhoneInput(
          number: phone.number,
          customLabel: phone.label.customLabel ?? '',
          label: phone.label.label,
        ));
      }
      for (final email in contact.emails) {
        _emailInputs.add(EmailInput(
          address: email.address,
          customLabel: email.label.customLabel ?? '',
          label: email.label.label,
        ));
      }
      for (int i = 0; i < contact.addresses.length; i++) {
        final address = contact.addresses[i];
        String link = '';
        if (i < contact.websites.length) {
          link = contact.websites[i].url;
        }
        _addressInputs.add(AddressInput(
          formatted: address.formatted ?? '',
          link: link,
        ));
      }
    }

    if (_phoneInputs.isEmpty) {
      _phoneInputs.add(PhoneInput(number: widget.initialPhone ?? ''));
    }
    if (_addressInputs.isEmpty) {
      _addressInputs.add(AddressInput());
    }
    
    _selectedGroupId = widget.groupId;
    
    _loadGroups();
  }

  // جلب كافة التصنيفات المتاحة لتحديد التصنيف الحالي لجهة الاتصال
  Future<void> _loadGroups() async {
    try {
      final groupService = RepositoryProvider.of<IGroupService>(context);
      final groups = await groupService.getGroups();
      
      String? contactGroupId;
      if (widget.contactToEdit?.id != null) {
        for (final group in groups) {
          final contactsInGroup = await groupService.getContactsInGroup(group.id);
          if (contactsInGroup.any((c) => c.id == widget.contactToEdit!.id)) {
            contactGroupId = group.id;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableGroups = groups;
          if (widget.contactToEdit != null) {
            _selectedGroupId = contactGroupId;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
    }
  }

  // إغلاق الحقول والتخلص من متحكمات النصوص لمنع تسريب الذاكرة
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _notesController.dispose();
    for (final input in _phoneInputs) {
      input.dispose();
    }
    for (final input in _emailInputs) {
      input.dispose();
    }
    for (final input in _addressInputs) {
      input.dispose();
    }
    super.dispose();
  }

  // فتح معرض الصور لاختيار صورة شخصية لجهة الاتصال
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // فتح شاشة تحديد العنوان الجغرافي واستقبال النتيجة لتحديث الحقول
  Future<void> _openAddressPage(AddressInput input) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressPage(
          initialAddress: input.controller.text,
          initialLink: input.linkController.text,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (result['address']?.isNotEmpty == true) {
          input.controller.text = result['address']!;
        }
        if (result['link']?.isNotEmpty == true) {
          input.linkController.text = result['link']!;
        }
      });
    }
  }

  // حفظ بيانات جهة الاتصال (إنشاء جديد أو تحديث حالي) وإرسال حدث لـ ContactsBloc
  Future<void> _saveContact() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty) {
      _showSnackBar('First name is required');
      return;
    }

    final phones = _phoneInputs
        .where((i) => i.controller.text.trim().isNotEmpty)
        .map((i) => Phone(
              number: i.controller.text.trim(),
              label: Label(i.label, i.label == PhoneLabel.custom ? i.customLabelController.text.trim() : ''),
            ))
        .toList();

    if (phones.isEmpty) {
      _showSnackBar('At least one phone number is required');
      return;
    }

    final emails = _emailInputs
        .where((i) => i.controller.text.trim().isNotEmpty)
        .map((i) => Email(
              address: i.controller.text.trim(),
              label: Label(i.label, i.label == EmailLabel.custom ? i.customLabelController.text.trim() : ''),
            ))
        .toList();

    final List<Address> addresses = [];
    final List<Website> websites = [];
    for (final input in _addressInputs) {
      if (input.controller.text.trim().isNotEmpty) {
        addresses.add(Address(formatted: input.controller.text.trim()));
        websites.add(Website(url: input.linkController.text.trim(), label: const Label(WebsiteLabel.other)));
      }
    }

    setState(() => _isSaving = true);

    final bloc = context.read<ContactsBloc>();
    Uint8List? photoBytes;
    if (_selectedImage != null) {
      photoBytes = await File(_selectedImage!.path).readAsBytes();
    }

    if (!mounted) return;
    final isEditing = widget.contactToEdit != null;

    if (isEditing) {
      final existing = widget.contactToEdit!;
      final updated = existing.copyWith(
        name: (existing.name ?? const Name()).copyWith(
          first: firstName,
          last: lastName,
        ),
        phones: phones,
        emails: emails,
        addresses: addresses,
        websites: websites,
        notes: _notesController.text.trim().isNotEmpty
            ? [Note(note: _notesController.text.trim())]
            : [],
        photo: photoBytes != null ? Photo(fullSize: photoBytes) : null,
      );
      bloc.add(UpdateContactEvent(updated, groupId: _selectedGroupId));
    } else {
      bloc.add(CreateContactEvent(
        firstName: firstName,
        lastName: lastName,
        phones: phones,
        emails: emails,
        addresses: addresses,
        websites: websites,
        notes: _notesController.text.trim(),
        photo: photoBytes,
        groupId: _selectedGroupId,
      ));
    }
  }

  // عرض شريط تنبيه منبثق برسالة معينة
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.contactToEdit != null;

    return BlocListener<ContactsBloc, ContactsState>(
      listenWhen: (previous, current) {
        if (current is! ContactsLoaded) return false;
        if (current.navigationAck != 'contactSaved') return false;
        if (previous is! ContactsLoaded) return true;
        return previous.navigationAck != current.navigationAck;
      },
      listener: (context, state) {
        context.read<ContactsBloc>().add(const ClearContactsNavigationAckEvent());
        if (mounted) {
          Navigator.pop(context, true);
        }
      },
      child: _buildAddContactScaffold(isEditing),
    );
  }

  Widget _buildAddContactScaffold(bool isEditing) {
    final existingPhoto =
        widget.contactToEdit?.photo?.fullSize ?? widget.contactToEdit?.photo?.thumbnail;
    return BlocListener<ContactsBloc, ContactsState>(
      listenWhen: (previous, current) => current is ContactsError,
      listener: (context, state) {
        if (state is ContactsError) {
          setState(() => _isSaving = false);
          _showSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF004080), size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            isEditing ? 'Edit Contact' : 'Add Contact',
            style: const TextStyle(
              color: Color(0xFF004080),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF33A1E5),
                          strokeWidth: 2.5,
                        ),
                      )
                    : InkWell(
                        onTap: _saveContact,
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Color(0xFF33A1E5),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Profile Section
                Center(
                  child: InkWell(
                    onTap: () => _pickImage(),
                    borderRadius: BorderRadius.circular(65),
                    child: Stack(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            shape: BoxShape.circle,
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(File(_selectedImage!.path)),
                                    fit: BoxFit.cover,
                                  )
                                : (existingPhoto != null
                                    ? DecorationImage(
                                        image: MemoryImage(existingPhoto),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: _selectedImage == null && existingPhoto == null
                              ? const Icon(Icons.person, size: 60, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF004080),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Form Fields
                _buildField(
                  label: 'First Name*',
                  hint: 'Enter first name',
                  controller: _firstNameController,
                ),
                _buildField(
                  label: 'Last Name*',
                  hint: 'Enter last name',
                  controller: _lastNameController,
                ),
                const SizedBox(height: 16),
                
                // Phones Section
                _buildSectionTitle('Phone Numbers'),
                for (int i = 0; i < _phoneInputs.length; i++) ...[
                  _buildPhoneField(i),
                  const SizedBox(height: 12),
                ],
                _buildAddButton('Add Phone', () => setState(() => _phoneInputs.add(PhoneInput()))),
                const SizedBox(height: 24),

                // Emails Section
                _buildSectionTitle('Emails'),
                for (int i = 0; i < _emailInputs.length; i++) ...[
                  _buildEmailField(i),
                  const SizedBox(height: 12),
                ],
                _buildAddButton('Add Email', () => setState(() => _emailInputs.add(EmailInput()))),
                const SizedBox(height: 24),

                // Addresses Section
                _buildSectionTitle('Addresses'),
                for (int i = 0; i < _addressInputs.length; i++) ...[
                  _buildAddressField(i),
                  const SizedBox(height: 24),
                ],
                _buildAddButton('Add Address', () => setState(() => _addressInputs.add(AddressInput()))),
                const SizedBox(height: 24),

                _buildField(
                  label: 'Notes*',
                  hint: 'Note',
                  controller: _notesController,
                ),
                _buildCategoryPicker(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF004080),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return Directionality(
                  textDirection: TextUtils.getTextDirection(value.text),
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    style: const TextStyle(
                      color: Color(0xFF004080),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      suffixIcon: suffixIcon,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF004080),
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF33A1E5),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // بناء مجموعة حقول إدخال الهاتف المحددة مع قائمة منسدلة لاختيار نوع الهاتف (جوال، عمل، منزل، إلخ)
  Widget _buildPhoneField(int index) {
    final input = _phoneInputs[index];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: index == 0 ? 'Phone Number*' : 'Secondary Phone',
                hint: 'Enter phone number',
                controller: input.controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                suffixIcon: DropdownButtonHideUnderline(
                  child: DropdownButton<PhoneLabel>(
                    value: input.label,
                    items: [PhoneLabel.mobile, PhoneLabel.home, PhoneLabel.work, PhoneLabel.main, PhoneLabel.other, PhoneLabel.custom].map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(l.name[0].toUpperCase() + l.name.substring(1), style: const TextStyle(fontSize: 12)),
                    )).toList(),
                    onChanged: (v) => setState(() => input.label = v!),
                  ),
                ),
              ),
            ),
            if (index > 0)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => setState(() => _phoneInputs.removeAt(index)),
              ),
          ],
        ),
        if (input.label == PhoneLabel.custom) ...[
          const SizedBox(height: 8),
          _buildField(
            label: 'Custom Label',
            hint: 'e.g. Grandma\'s House',
            controller: input.customLabelController,
          ),
        ],
      ],
    );
  }

  // بناء حقل إدخال البريد الإلكتروني مع خيارات التسمية (منزل، عمل، مخصص)
  Widget _buildEmailField(int index) {
    final input = _emailInputs[index];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                label: 'Email',
                hint: 'Enter email address',
                controller: input.controller,
                suffixIcon: DropdownButtonHideUnderline(
                  child: DropdownButton<EmailLabel>(
                    value: input.label,
                    items: [EmailLabel.home, EmailLabel.work, EmailLabel.other, EmailLabel.custom].map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(l.name[0].toUpperCase() + l.name.substring(1), style: const TextStyle(fontSize: 12)),
                    )).toList(),
                    onChanged: (v) => setState(() => input.label = v!),
                  ),
                ),
              ),
            ),
            if (index > 0 || _emailInputs.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => setState(() => _emailInputs.removeAt(index)),
              ),
          ],
        ),
        if (input.label == EmailLabel.custom) ...[
          const SizedBox(height: 8),
          _buildField(
            label: 'Custom Label',
            hint: 'Enter custom label',
            controller: input.customLabelController,
          ),
        ],
      ],
    );
  }

  // بناء حقل إدخال العنوان الجغرافي مدمجاً معه معاينة مصغرة للخريطة التفاعلية
  Widget _buildAddressField(int index) {
    final input = _addressInputs[index];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _openAddressPage(input),
                child: AbsorbPointer(
                  child: _buildField(
                    label: index == 0 ? 'Primary Address' : 'Additional Address',
                    hint: 'Enter address',
                    controller: input.controller,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Image.asset(
                        'assets/images/add contact/gps 1.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (index > 0)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => setState(() => _addressInputs.removeAt(index)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Mini Map Preview
        GestureDetector(
          onTap: () => _openAddressPage(input),
          child: Builder(
            builder: (context) {
              final link = input.linkController.text;
              final latLng = link.isNotEmpty ? MapUtils.parseLocationLink(link) : null;
              final center = latLng ?? const LatLng(30.0444, 31.2357);
              final hasLocation = latLng != null;

              return Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: IgnorePointer(
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: hasLocation ? 15 : 10,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.contact_navigator',
                            ),
                            if (hasLocation)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: latLng,
                                    width: 30,
                                    height: 30,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_location_alt, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            hasLocation ? 'Change' : 'Set',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // بناء أداة اختيار تصنيف/مجموعة جهة الاتصال (Category Picker)
  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: Text(
            'Category',
            style: TextStyle(
              color: Color(0xFF004080),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGroupId,
              isExpanded: true,
              hint: const Text('Select a category'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._availableGroups.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name),
                )),
              ],
              onChanged: (v) => setState(() => _selectedGroupId = v),
            ),
          ),
        ),
      ],
    );
  }
}
