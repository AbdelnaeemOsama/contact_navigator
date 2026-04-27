import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';
import 'package:contact_navigator/features/call/call_screen.dart';

class CategoryContact {
  final String name;
  final String phone;
  final String imagePath;
  final Color bgColor;

  CategoryContact({
    required this.name,
    required this.phone,
    required this.imagePath,
    required this.bgColor,
  });
}

class CategoryContactsPage extends StatefulWidget {
  final String categoryTitle;

  const CategoryContactsPage({super.key, required this.categoryTitle});

  @override
  State<CategoryContactsPage> createState() => _CategoryContactsPageState();
}

class _CategoryContactsPageState extends State<CategoryContactsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<CategoryContact> _allContacts = [];
  List<CategoryContact> _filteredContacts = [];
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    // Dummy data based on the provided image
    _allContacts = [
      CategoryContact(
        name: 'Arwa',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/woman 1.png',
        bgColor: const Color(0xFFD4E4FC),
      ),
      CategoryContact(
        name: 'Anas',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/man 1.png',
        bgColor: const Color(0xFFC2E8FF),
      ),
      CategoryContact(
        name: 'Menna',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/woman_2.png',
        bgColor: const Color(0xFFFFE5E5),
      ),
      CategoryContact(
        name: 'Osama',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/boy 1.png',
        bgColor: const Color(0xFFE5E7EB),
      ),
      CategoryContact(
        name: 'Maryam',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/woman_3.png',
        bgColor: const Color(0xFFD4E4FC),
      ),
      CategoryContact(
        name: 'Omar',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/employee.png',
        bgColor: const Color(0xFFC2E8FF),
      ),
      CategoryContact(
        name: 'Rowida',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/woman_2.png',
        bgColor: const Color(0xFFFFB2C1),
      ),
    ];
    _filteredContacts = _allContacts;
  }

  void _filterContacts(String query) {
    setState(() {
      _expandedIndex = null;
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts
            .where(
              (contact) =>
                  contact.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lightBlue = Color(0xFF33A1E5);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlue, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.categoryTitle} Contact',
          style: const TextStyle(
            color: AppColors.textBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterContacts,
                decoration: InputDecoration(
                  hintText: 'Search contacts',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/Categories/loupe 3.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Contact List
            Expanded(
              child: ListView.separated(
                itemCount: _filteredContacts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  final bool isExpanded = _expandedIndex == index;
                  
                  return Dismissible(
                    key: Key('cat_contact_${contact.name}_${contact.phone}_$index'),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CallScreen(name: contact.name, imagePath: contact.imagePath),
                          ),
                        );
                      }
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/icons_contact_page/phone-call (1).png',
                        width: 32,
                        height: 32,
                        color: const Color(0xFF33A1E5),
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/icons_contact_page/gps-navigation 1.png',
                        width: 32,
                        height: 32,
                        color: const Color(0xFF33A1E5),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedIndex = isExpanded ? null : index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: isExpanded ? const EdgeInsets.all(16) : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: isExpanded ? const Color(0xFFB9BFD6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Contact Avatar
                                CircleAvatar(
                                  radius: isExpanded ? 28 : 30,
                                  backgroundColor: contact.bgColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: ClipOval(
                                      child: Image.asset(
                                        contact.imagePath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Contact Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: const TextStyle(
                                          color: AppColors.textBlue,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isExpanded)
                                        const Text(
                                          'Address',
                                          style: TextStyle(
                                            color: AppColors.textBlue,
                                            fontSize: 14,
                                          ),
                                        )
                                      else ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          contact.phone,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isExpanded)
                                  Text(
                                    contact.phone,
                                    style: const TextStyle(
                                      color: AppColors.textBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else
                                  Image.asset(
                                    'assets/images/icons_contact_page/right-arrow 1.png',
                                    width: 20,
                                    height: 20,
                                  ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildActionIcon(
                                    'assets/images/icons/phone_call.png',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CallScreen(name: contact.name, imagePath: contact.imagePath),
                                      ),
                                    ),
                                  ),
                                  _buildActionIcon(
                                    '',
                                    icon: Icons.edit_note,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddContactPage(
                                          contactToEdit: {
                                            'name': contact.name,
                                            'phone': contact.phone,
                                            'imagePath': contact.imagePath,
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildActionIcon(
                                    'assets/images/icons/location.png',
                                  ),
                                  _buildActionIcon(
                                    'assets/images/icons/map.png',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContactPage(),
            ),
          );
        },
        backgroundColor: lightBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildActionIcon(
    String path, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: icon != null
            ? Icon(
                icon,
                size: 32,
                color: const Color(0xFF33A1E5),
              )
            : Image.asset(
                path,
                width: 32,
                height: 32,
                color: const Color(0xFF33A1E5),
              ),
      ),
    );
  }
}
