import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/features/contacts/add_contact_page.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/features/contacts/categories_page.dart';
import 'package:contact_navigator/features/keypad/keypad_page.dart';
import 'package:contact_navigator/features/settings/settings_page.dart';
import 'package:contact_navigator/features/map/map_tab.dart';
import 'bloc/contacts_bloc.dart';
import 'bloc/contacts_event.dart';
import 'bloc/contacts_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/contact_list_item.dart';
import 'widgets/contacts_search_bar.dart';
import 'widgets/contacts_favorites_section.dart';
import 'package:contact_navigator/core/widgets/custom_bottom_nav.dart';
import 'package:latlong2/latlong.dart';
import 'package:contact_navigator/core/services/settings_service.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  int _selectedIndex = 0;
  int? _expandedIndex;
  LatLng? _mapFocusLocation;

  final GlobalKey<CategoriesPageState> _categoriesKey = GlobalKey<CategoriesPageState>();

  @override
  void initState() {
    super.initState();
    context.read<ContactsBloc>().add(LoadContactsEvent());
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _expandedIndex = null;
    });
    context.read<ContactsBloc>().add(SearchContactsEvent(query));
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
    final settingsService = context.read<SettingsService>();
    final favorites = state.allContacts.where((c) => settingsService.isFavorite(c.id ?? '')).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: state.filteredContacts.length + 4,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ContactsSearchBar(onQueryChanged: _onSearchQueryChanged);
        } else if (index == 1) {
          return ContactsFavoritesSection(
            favorites: favorites,
            nameFormat: state.nameFormat,
          );
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
      case 1:
        return KeypadPage(
          onNavigateToMap: (latLng) {
            setState(() {
              _mapFocusLocation = latLng;
              _selectedIndex = 2;
            });
          },
        );
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

}
