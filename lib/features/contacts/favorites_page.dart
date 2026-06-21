import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/widgets/contact_list_item.dart';
import 'package:latlong2/latlong.dart';

class FavoritesPage extends StatefulWidget {
  final List<Contact> favorites;
  final void Function(LatLng location)? onNavigateToMap;

  const FavoritesPage({
    super.key,
    required this.favorites,
    this.onNavigateToMap,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  int? _expandedIndex;

  Color _contactColor(String name) {
    final hash = name.isNotEmpty ? name.codeUnitAt(0) : 0;
    return AppColors.contactAvatarColors[hash % AppColors.contactAvatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: AppColors.textBlue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: widget.favorites.isEmpty
          ? const Center(
              child: Text(
                'No favorites yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : BlocBuilder<ContactsBloc, ContactsState>(
              builder: (context, state) {
                final nameFormat = state is ContactsLoaded
                    ? state.nameFormat
                    : ContactNameFormat.firstLast;
                final favoriteIds = state is ContactsLoaded
                    ? state.favoriteIds
                    : <String>{};

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.favorites.length,
                  itemBuilder: (context, index) {
                    final contact = widget.favorites[index];
                    return ContactListItem(
                      key: ValueKey(contact.id ?? 'favorite_$index'),
                      index: index,
                      contact: contact,
                      bgColor: _contactColor(contact.displayName ?? ''),
                      nameFormat: nameFormat,
                      isFavorite: favoriteIds.contains(contact.id),
                      isExpanded: _expandedIndex == index,
                      onTap: () {
                        setState(() {
                          _expandedIndex = _expandedIndex == index ? null : index;
                        });
                        if (_expandedIndex == index) {
                          context.read<VoiceAssistantService>().speak(
                                contact.displayName ?? '',
                              );
                        }
                      },
                      onNavigateToMap: widget.onNavigateToMap,
                    );
                  },
                );
              },
            ),
    );
  }
}
