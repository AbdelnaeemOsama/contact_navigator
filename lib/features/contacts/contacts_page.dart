import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/favorites_page.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/features/contacts/categories_page.dart';
import 'package:contact_navigator/features/keypad/keypad_page.dart';
import 'package:contact_navigator/features/settings/settings_page.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';
import 'package:contact_navigator/features/map/map_tab.dart';
import 'bloc/contacts_bloc.dart';
import 'bloc/contacts_event.dart';
import 'bloc/contacts_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'widgets/contact_list_item.dart';
import 'package:contact_navigator/core/widgets/custom_bottom_nav.dart';
import 'package:latlong2/latlong.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  int _selectedIndex = 0;
  int? _expandedIndex;
  LatLng? _mapFocusLocation;

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

  Widget _buildContactsTab(Color lightBlue) {
    return BlocListener<ContactsBloc, ContactsState>(
      listenWhen: (previous, current) {
        if (current is! ContactsLoaded) return false;
        final msg = current.snackbarMessage;
        if (msg == null || msg.isEmpty) return false;
        if (previous is! ContactsLoaded) return true;
        return previous.snackbarMessage != current.snackbarMessage;
      },
      listener: (context, state) {
        final loaded = state as ContactsLoaded;
        final message = loaded.snackbarMessage;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<ContactsBloc>().add(const ClearContactsSnackBarEvent());
      },
      child: BlocBuilder<ContactsBloc, ContactsState>(
        builder: (context, state) {
          if (state is ContactsLoading || state is ContactsInitial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: lightBlue),
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
            return _buildErrorState(state.message, lightBlue);
          } else if (state is ContactsPermissionDenied) {
            return _buildPermissionDeniedState(lightBlue);
          } else if (state is ContactsLoaded) {
            final loaded = state;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildContactsList(loaded, lightBlue),
                if (loaded.isRefreshing)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: lightBlue,
                      backgroundColor: lightBlue.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildContactsList(ContactsLoaded state, Color lightBlue) {
    final favorites = state.allContacts.where((c) => c.android?.isFavorite ?? false).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: state.filteredContacts.length + 4,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSearchBar();
        } else if (index == 1) {
          return _buildFavoritesSection(favorites, state.nameFormat);
        } else if (index == 2) {
          return _buildSectionHeader('All Contacts');
        } else if (index == state.filteredContacts.length + 3) {
          return const SizedBox(height: 120);
        }

        final contactIndex = index - 3;
        final contact = state.filteredContacts[contactIndex];
        return ContactListItem(
          index: contactIndex,
          contact: contact,
          bgColor: _getContactColor(contact.displayName ?? ''),
          nameFormat: state.nameFormat,
          isExpanded: _expandedIndex == contactIndex,
          onTap: () {
            setState(() {
              _expandedIndex = _expandedIndex == contactIndex ? null : contactIndex;
            });
            if (_expandedIndex == contactIndex) {
              context.read<VoiceAssistantService>().speak(contact.displayName ?? '');
            }
          },
          onNavigateToMap: (latLng) {
            setState(() {
              _mapFocusLocation = latLng;
              _selectedIndex = 2;
            });
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return Directionality(
                textDirection: TextUtils.getTextDirection(value.text),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterContacts,
                  decoration: const InputDecoration(
                    hintText: 'Search contacts',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey, size: 24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(List<Contact> favorites, ContactNameFormat nameFormat) {
    if (favorites.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Favorites', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlue)),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesPage(favorites: favorites))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            itemBuilder: (context, fIndex) {
              final c = favorites[fIndex];
              return Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: _buildFavoriteItem(c, _getContactColor(c.displayName ?? ''), nameFormat),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBlue)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const lightBlue = Color(0xFF33A1E5);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(lightBlue),
      ),
      floatingActionButton: _buildFab(lightBlue),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget? _buildFab(Color lightBlue) {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddContactPage()));
          if (result == true && mounted) {
            context.read<ContactsBloc>().add(LoadContactsEvent());
          }
        },
        backgroundColor: lightBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      );
    } else if (_selectedIndex == 3) {
      return FloatingActionButton(
        onPressed: () => _categoriesKey.currentState?.showAddCategoryDialog(context),
        backgroundColor: lightBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      );
    }
    return null;
  }

  Widget _buildBody(Color lightBlue) {
    switch (_selectedIndex) {
      case 0: return _buildContactsTab(lightBlue);
      case 1: return const KeypadPage();
      case 2: return MapTab(key: ValueKey(_mapFocusLocation), focusLocation: _mapFocusLocation);
      case 3: return CategoriesPage(key: _categoriesKey);
      case 4: return const SettingsPage(isTab: true);
      default: return _buildContactsTab(lightBlue);
    }
  }

  Widget _buildErrorState(String message, Color lightBlue) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<ContactsBloc>().add(LoadContactsEvent()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState(Color lightBlue) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_page_outlined, size: 72, color: lightBlue.withValues(alpha: 0.85)),
            const SizedBox(height: 20),
            const Text(
              'Contacts access is off',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Allow contacts in system settings so Contact Navigator can show and manage your list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textBlue.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              style: FilledButton.styleFrom(
                backgroundColor: lightBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.settings_outlined, size: 22),
              label: const Text('Open settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<ContactsBloc>().add(const LoadContactsEvent()),
              child: Text('Try again', style: TextStyle(fontWeight: FontWeight.w600, color: lightBlue)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContactColor(String name) {
    final colors = [const Color(0xFFD4E4FC), const Color(0xFFC2E8FF), const Color(0xFFFF7B93), const Color(0xFFE5E7EB)];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildFavoriteItem(Contact contact, Color bgColor, ContactNameFormat nameFormat) {
    final photo = contact.photo?.thumbnail;
    final name = _getFormattedName(contact, nameFormat);
    return GestureDetector(
      onTap: () => _makeCall(contact),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: bgColor.withValues(alpha: 0.3),
            backgroundImage: photo != null ? MemoryImage(photo) : null,
            child: photo == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(height: 8),
          SizedBox(width: 75, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBlue))),
        ],
      ),
    );
  }

  String _getFormattedName(Contact contact, ContactNameFormat format) {
    if (contact.name == null) return contact.displayName ?? '';
    
    final first = contact.name!.first;
    final last = contact.name!.last;
    
    if (format == ContactNameFormat.firstLast) {
      return '$first $last'.replaceAll('null', '').trim();
    } else {
      return '$last $first'.replaceAll('null', '').trim();
    }
  }

  Future<void> _makeCall(Contact contact) async {
    if (contact.phones.isEmpty) return;
    await FlutterPhoneDirectCaller.callNumber(contact.phones.first.number);
  }
}
