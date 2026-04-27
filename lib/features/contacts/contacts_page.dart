import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/call/call_screen.dart';
import 'package:contact_navigator/features/contacts/favorites_page.dart';
import 'package:contact_navigator/features/keypad/keypad_page.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';
import 'package:contact_navigator/features/contacts/categories_page.dart';
import 'package:contact_navigator/features/profile/profile_page.dart';
import 'package:contact_navigator/features/settings/settings_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';
import 'bloc/contacts_bloc.dart';
import 'bloc/contacts_event.dart';
import 'bloc/contacts_state.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  int _selectedIndex = 0;
  int? _expandedIndex; // To track which contact is expanded

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<CategoriesPageState> _categoriesKey = GlobalKey<CategoriesPageState>();

  @override
  void initState() {
    super.initState();
    context.read<ContactsBloc>().add(LoadContactsEvent());
  }

  void _filterContacts(String query) {
    setState(() {
      _expandedIndex = null;
    });
    context.read<ContactsBloc>().add(SearchContactsEvent(query));
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
        case 1:
          return const KeypadPage();
        case 3:
          return CategoriesPage(key: _categoriesKey);
        case 4:
          return const SettingsPage(isTab: true);
        case 0:
        default:
          if (_selectedIndex == 2) {
             return const Center(child: Text('Map View')); 
          }
          return BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              if (state is ContactsLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: lightBlue),
                      const SizedBox(height: 20),
                      Text(
                        'Loading contacts...',
                        style: TextStyle(
                          color: AppColors.textBlue.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is ContactsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Something went wrong',
                          style: TextStyle(
                            color: AppColors.textBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<ContactsBloc>().add(LoadContactsEvent());
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lightBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is ContactsPermissionDenied) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: lightBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.contacts_rounded,
                            color: lightBlue,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Permission Required',
                          style: TextStyle(
                            color: AppColors.textBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Contact Navigator needs access to your contacts to display and manage them. Please grant permission in settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<ContactsBloc>().add(LoadContactsEvent());
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lightBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () async {
                            await openAppSettings();
                          },
                          child: const Text(
                            'Open Settings',
                            style: TextStyle(
                              color: lightBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is ContactsInitial) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        color: lightBlue,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to load contacts',
                        style: TextStyle(
                          color: AppColors.textBlue.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ContactsBloc>().add(LoadContactsEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Load Contacts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is ContactsLoaded) {
                final favorites = state.allContacts.take(5).toList();
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
                        if (_searchController.text.isEmpty && favorites.isNotEmpty) ...[
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
                                        favorites: favorites,
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
                              children: favorites
                                  .map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: _buildFavoriteItem(
                                        c.photo?.thumbnail,
                                        c.displayName ?? '',
                                        _getContactColor(c.displayName ?? ''),
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
                        ...List.generate(state.filteredContacts.length, (index) {
                          final contact = state.filteredContacts[index];
                          return _buildContactItem(
                            index,
                            contact.photo?.thumbnail,
                            contact.displayName ?? '',
                            contact.phones.isNotEmpty ? contact.phones.first.number : '',
                            _getContactColor(contact.displayName ?? ''),
                          );
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectedIndex == 1
              ? 'Keypad'
              : _selectedIndex == 3
                  ? 'Categories'
                  : _selectedIndex == 2
                      ? 'Map'
                      : _selectedIndex == 4
                          ? 'Settings'
                          : 'Contacts',
          style: const TextStyle(
            color: AppColors.textBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: null,
        actions: [
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.textBlue, size: 32),
              onPressed: () {
                _categoriesKey.currentState?.showAddCategoryDialog(context);
              },
            ),
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
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
            ),
        ],
      ),
      body: getBody(),
      floatingActionButton: _selectedIndex != 0
          ? null
            : FloatingActionButton(
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
                'assets/images/icons_contact_page/dial-pad 1.png',
                1,
              ),
              label: 'Keypad',
            ),
            BottomNavigationBarItem(
              icon: _buildBottomNavIcon(
                'assets/images/icons_contact_page/map (1) 1.png',
                2,
              ),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: _buildBottomNavIcon(
                'assets/images/icons_contact_page/categories 1.png',
                3,
              ),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: _buildBottomNavIcon('', 4, isSettings: true),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavIcon(String path, int index, {bool isSettings = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: isSettings 
        ? Icon(
            Icons.settings,
            size: 24,
            color: _selectedIndex == index 
                ? Colors.white 
                // ignore: deprecated_member_use
                : Colors.white.withOpacity(0.7),
          )
        : Image.asset(
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

  Color _getContactColor(String name) {
    final colors = [const Color(0xFFD4E4FC), const Color(0xFFC2E8FF), const Color(0xFFFF7B93), const Color(0xFFE5E7EB)];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildFavoriteItem(Uint8List? photo, String name, Color bgColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: bgColor,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipOval(child: photo != null ? Image.memory(photo, fit: BoxFit.cover) : const Icon(Icons.person, color: Colors.white)),
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
    Uint8List? photo,
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
                  CallScreen(name: name, imagePath: ''),
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
                        child: photo != null ? Image.memory(photo, fit: BoxFit.cover) : const Icon(Icons.person, color: Colors.white),
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
                              CallScreen(name: name, imagePath: ''),
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
                              'name': name,
                              'phone': phone,
                              'photo': photo,
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
