import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/features/contacts/categories_page.dart';
import 'package:contact_navigator/features/keypad/keypad_page.dart';
import 'package:contact_navigator/features/settings/settings_page.dart';
import 'package:contact_navigator/features/map/map_tab.dart';
import 'package:contact_navigator/features/voice_assistant/widgets/voice_assistant_widget.dart';
import 'bloc/contacts_bloc.dart';
import 'bloc/contacts_event.dart';
import 'bloc/contacts_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/contact_list_item.dart';
import 'widgets/contacts_search_bar.dart';
import 'contacts_search_page.dart';
import 'widgets/contacts_favorites_section.dart';
import 'package:contact_navigator/core/widgets/custom_bottom_nav.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_contacts/flutter_contacts.dart';


class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  int _selectedIndex = 0;
  String? _expandedContactId;
  LatLng? _mapFocusLocation;
  bool _mapVisited = false;

  final GlobalKey<CategoriesPageState> _categoriesKey = GlobalKey<CategoriesPageState>();

  void _openContactsSearch() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ContactsSearchPage(onNavigateToMap: _navigateToMap),
      ),
    );
  }

  void _onContactTap(Contact contact) {
    final contactId = contact.id;
    setState(() {
      _expandedContactId =
          _expandedContactId == contactId ? null : contactId;
    });
    if (_expandedContactId == contactId) {
      context.read<VoiceAssistantService>().speak(contact.displayName ?? '');
    }
  }

  void _navigateToMap(LatLng latLng) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _mapFocusLocation = latLng;
          _selectedIndex = 2;
        });
      }
    });
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
        final isError = message.startsWith('Failed to');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red.shade700 : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<ContactsBloc>().add(const ClearContactsSnackBarEvent());
      },
      child: BlocBuilder<ContactsBloc, ContactsState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (current is ContactsLoaded && previous is ContactsLoaded) {
            return previous.allContacts != current.allContacts ||
                previous.favoriteIds != current.favoriteIds ||
                previous.nameFormat != current.nameFormat ||
                previous.sortOrder != current.sortOrder;
          }
          return true;
        },
        builder: (context, state) {
          if (state is ContactsError) {
            return _buildErrorState(state.message, lightBlue);
          } else if (state is ContactsPermissionDenied) {
            return _buildPermissionDeniedState(lightBlue);
          } else if (state is ContactsLoaded ||
              state is ContactsLoading ||
              state is ContactsInitial) {
            final loaded = state is ContactsLoaded
                ? state
                : const ContactsLoaded(
                    allContacts: [],
                    filteredContacts: [],
                  );
            return _buildContactsList(loaded, lightBlue);
          }

          return _buildContactsList(
            const ContactsLoaded(allContacts: [], filteredContacts: []),
            lightBlue,
          );
        },
      ),
    );
  }

  Widget _buildContactsList(ContactsLoaded state, Color lightBlue) {
    final favorites = state.allContacts.where((c) => state.favoriteIds.contains(c.id)).toList();
    final contacts = state.allContacts;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      cacheExtent: 400,
      itemCount: contacts.length + 4,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ContactsSearchBar(onTap: _openContactsSearch);
        } else if (index == 1) {
          return ContactsFavoritesSection(
            favorites: favorites,
            nameFormat: state.nameFormat,
            favoriteIds: state.favoriteIds,
            expandedContactId: _expandedContactId,
            onContactTap: _onContactTap,
            onNavigateToMap: _navigateToMap,
            contactColor: _getContactColor,
          );
        } else if (index == 2) {
          return _buildSectionHeader('All Contacts');
        } else if (index == contacts.length + 3) {
          return const SizedBox(height: 120);
        }

        final contactIndex = index - 3;
        final contact = contacts[contactIndex];
        return ContactListItem(
          key: ValueKey(contact.id ?? 'contact_$contactIndex'),
          index: contactIndex,
          contact: contact,
          bgColor: _getContactColor(contact.displayName ?? ''),
          nameFormat: state.nameFormat,
          isFavorite: state.favoriteIds.contains(contact.id),
          isExpanded: _expandedContactId != null &&
              _expandedContactId == contact.id,
          onTap: () => _onContactTap(contact),
          onNavigateToMap: _navigateToMap,
        );
      },
      ),
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

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Main content with bottom padding so content doesn't hide behind nav
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: _buildBody(lightBlue),
              ),
            ),
            // Floating bottom nav overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNav(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) => setState(() {
                  _selectedIndex = index;
                  if (index == 2) _mapVisited = true;
                }),
              ),
            ),
            // FAB overlay
            if (_buildFab(lightBlue) != null)
              Positioned(
                right: 16,
                bottom: 120,
                child: _buildFab(lightBlue)!,
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab(Color lightBlue) {
    // No FAB at all on keypad tab
    if (_selectedIndex == 1) return null;

    final List<Widget> fabs = [];

    if (_selectedIndex == 0) {
      fabs.add(FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddContactPage()));
          if (result == true && mounted) {
            context.read<ContactsBloc>().add(LoadContactsEvent());
          }
        },
        backgroundColor: lightBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ));
    } else if (_selectedIndex == 3) {
      fabs.add(FloatingActionButton(
        onPressed: () => _categoriesKey.currentState?.showAddCategoryDialog(context),
        backgroundColor: lightBlue,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ));
    }

    // Don't show voice FAB on keypad tab (index 1)
    if (_selectedIndex != 1) {
      fabs.add(const VoiceAssistantFab());
    }

    if (fabs.isEmpty) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fabs.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          fabs[i],
        ],
      ],
    );
  }

  Widget _buildBody(Color lightBlue) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildContactsTab(lightBlue),
        KeypadPage(onNavigateToMap: _navigateToMap),
        _mapVisited
            ? MapTab(
                key: ValueKey(_mapFocusLocation),
                focusLocation: _mapFocusLocation,
              )
            : const SizedBox.shrink(),
        CategoriesPage(key: _categoriesKey),
        const SettingsPage(isTab: true),
      ],
    );
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
    final hash = name.isNotEmpty ? name.codeUnitAt(0) : 0;
    return AppColors.contactAvatarColors[hash % AppColors.contactAvatarColors.length];
  }

}