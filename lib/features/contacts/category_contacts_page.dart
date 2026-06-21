import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:contact_navigator/features/contacts/select_contacts_page.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/bloc/group_contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/group_contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/group_contacts_state.dart';
import 'package:contact_navigator/features/contacts/widgets/contact_list_item.dart';

class CategoryContactsPage extends StatefulWidget {
  final String categoryTitle;
  final String groupId;

  const CategoryContactsPage({
    super.key,
    required this.categoryTitle,
    required this.groupId,
  });

  @override
  State<CategoryContactsPage> createState() => _CategoryContactsPageState();
}

class _CategoryContactsPageState extends State<CategoryContactsPage> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    context.read<GroupContactsBloc>().add(LoadGroupContactsEvent(widget.groupId));
  }

  void _filterContacts(String query) {
    setState(() => _expandedIndex = null);
    context.read<GroupContactsBloc>().add(SearchGroupContactsEvent(query));
  }

  Future<void> _navigatorPushToSelectContacts(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectContactsPage(
          groupId: widget.groupId,
          categoryTitle: widget.categoryTitle,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      this.context.read<GroupContactsBloc>().add(LoadGroupContactsEvent(widget.groupId));
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Contacts added to ${widget.categoryTitle}'),
            backgroundColor: AppColors.primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Color _getContactColor(String name) {
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(
            color: AppColors.textBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue),
            onPressed: () {
              _navigatorPushToSelectContacts(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: 'Search in ${widget.categoryTitle}',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<GroupContactsBloc, GroupContactsState>(
              builder: (context, state) {
                if (state is GroupContactsError) {
                  return Center(child: Text('Error: ${state.message}'));
                } else if (state is GroupContactsLoaded) {
                  if (state.filteredContacts.isEmpty) {
                    return const Center(child: Text('No contacts found'));
                  }
                  return _buildContactList(state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(GroupContactsLoaded state) {
    final contactsState = context.read<ContactsBloc>().state;
    final nameFormat = contactsState is ContactsLoaded ? contactsState.nameFormat : ContactNameFormat.firstLast;
    final favoriteIds = contactsState is ContactsLoaded ? contactsState.favoriteIds : const <String>{};

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      cacheExtent: 400,
      itemCount: state.filteredContacts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final contact = state.filteredContacts[index];

        return ContactListItem(
          key: ValueKey(contact.id ?? 'group_contact_$index'),
          index: index,
          contact: contact,
          bgColor: _getContactColor(contact.displayName ?? 'Unknown'),
          nameFormat: nameFormat,
          isFavorite: favoriteIds.contains(contact.id),
          isExpanded: _expandedIndex == index,
          onTap: () {
            setState(() {
              _expandedIndex = _expandedIndex == index ? null : index;
            });
            if (_expandedIndex == index) {
              context.read<VoiceAssistantService>().speak(
                contact.displayName ?? 'Unknown',
              );
            }
          },
          onDelete: () {
            context.read<GroupContactsBloc>().add(LoadGroupContactsEvent(widget.groupId));
          },
          onRemoveFromGroup: () {
            if (contact.id != null && context.mounted) {
              context.read<VoiceAssistantService>().speak(
                'Removed ${contact.displayName} from ${widget.categoryTitle}',
              );
              context.read<GroupContactsBloc>().add(
                RemoveContactFromGroupEvent(contact.id!, widget.groupId),
              );
            }
          },
        );
      },
    );
  }
}
