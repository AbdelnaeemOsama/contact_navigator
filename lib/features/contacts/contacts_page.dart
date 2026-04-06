import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/call/call_screen.dart';
import 'package:contact_navigator/features/contacts/favorites_page.dart';
import 'package:contact_navigator/features/keypad/keypad_page.dart';

class Contact {
  final String name;
  final String phone;
  final String imagePath;
  final Color bgColor;
  final bool isFavorite;

  Contact({
    required this.name,
    required this.phone,
    required this.imagePath,
    required this.bgColor,
    this.isFavorite = false,
  });
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  int _selectedIndex = 0;
  int? _expandedIndex; // To track which contact is expanded

  final TextEditingController _searchController = TextEditingController();
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _allContacts = [
      Contact(
        name: 'Esraa',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/woman 1.png',
        bgColor: const Color(0xFFD4E4FC),
        isFavorite: true,
      ),
      Contact(
        name: 'El Sayed',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/man 1.png',
        bgColor: const Color(0xFFC2E8FF),
        isFavorite: true,
      ),
      Contact(
        name: 'Logy',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/woman_2.png',
        bgColor: const Color(0xFFFF7B93),
        isFavorite: true,
      ),
      Contact(
        name: 'Walid',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/boy2.png',
        bgColor: const Color(0xFFD4E4FC),
        isFavorite: true,
      ),
      Contact(
        name: 'Omar',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/employee.png',
        bgColor: const Color(0xFFE5E7EB),
      ),
      Contact(
        name: 'Alaa',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/woman_3.png',
        bgColor: const Color(0xFFFF7B93),
      ),
      Contact(
        name: 'Abdelnaeem',
        phone: '01000000000',
        imagePath: 'assets/images/icons_contact_page/boy 1.png',
        bgColor: const Color(0xFFE5E7EB),
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

    Widget getBody() {
      switch (_selectedIndex) {
        case 3:
          return const KeypadPage();
        case 0:
        default:
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
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
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/icons_contact_page/loupe 1.png',
                            width: 20,
                            height: 20,
                            color: Colors.grey,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_searchController.text.isEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Favorites',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlue,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FavoritesPage(
                                  favorites: _allContacts
                                      .where((c) => c.isFavorite)
                                      .toList(),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              // ignore: deprecated_member_use
                              color: AppColors.textBlue.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _allContacts
                            .where((c) => c.isFavorite)
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: _buildFavoriteItem(
                                  c.imagePath,
                                  c.name,
                                  c.bgColor,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'All Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_filteredContacts.length, (index) {
                    final contact = _filteredContacts[index];
                    return _buildContactItem(
                      index,
                      contact.imagePath,
                      contact.name,
                      contact.phone,
                      contact.bgColor,
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectedIndex == 3 ? 'Keypad' : 'Contacts',
          style: const TextStyle(
            color: AppColors.textBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedIndex != 3)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/icons_contact_page/boy 1.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: getBody(),
      floatingActionButton: _selectedIndex == 3
          ? null
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: lightBlue,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          // ignore: deprecated_member_use
          unselectedItemColor: Colors.white.withOpacity(0.7),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: _buildBottomNavIcon(
                'assets/images/icons_contact_page/profile 1.png',
                0,
              ),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: _buildBottomNavIcon(
                'assets/images/icons_contact_page/map (1) 1.png',
                1,
              ),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: _buildBottomNavIcon(
                'assets/images/icons_contact_page/categories 1.png',
                2,
              ),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: _buildBottomNavIcon(
                'assets/images/icons_contact_page/dial-pad 1.png',
                3,
              ),
              label: 'Keypad',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(String path, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Image.asset(
        path,
        width: 24,
        height: 24,
        color: _selectedIndex == index
            ? Colors.white
            // ignore: deprecated_member_use
            : Colors.white.withOpacity(0.7),
      ),
    );
  }

  Widget _buildFavoriteItem(String imagePath, String name, Color bgColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: bgColor,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipOval(child: Image.asset(imagePath, fit: BoxFit.cover)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    int index,
    String imagePath,
    String name,
    String phone,
    Color bgColor,
  ) {
    final bool isExpanded = _expandedIndex == index;

    return Dismissible(
      key: Key('contact_${name}_$phone'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CallScreen(name: name, imagePath: imagePath),
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
          margin: const EdgeInsets.only(bottom: 16),
          padding: isExpanded ? const EdgeInsets.all(16) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isExpanded ? const Color(0xFFB9BFD6) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isExpanded ? 28 : 30,
                    backgroundColor: bgColor,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        child: Image.asset(imagePath, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
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
                            phone,
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
                      phone,
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
                              CallScreen(name: name, imagePath: imagePath),
                        ),
                      ),
                    ),
                    _buildActionIcon(
                      'assets/images/icons_contact_page/loupe 1.png',
                      isMessage: true,
                    ),
                    _buildActionIcon(
                      'assets/images/icons_contact_page/right-arrow 1.png',
                      isNavigate: true,
                    ),
                    _buildActionIcon('assets/images/icons/location.png'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    String path, {
    bool isMessage = false,
    bool isNavigate = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          isMessage
              ? 'assets/images/icons/contact.png'
              : (isNavigate ? 'assets/images/icons/location.png' : path),
          width: 32,
          height: 32,
          color: const Color(0xFF33A1E5),
        ),
      ),
    );
  }
}
