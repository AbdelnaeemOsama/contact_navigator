import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/services/voice_service.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'package:contact_navigator/features/contacts/select_contacts_page.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/widgets/contact_list_item.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';

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
  late IGroupService _groupService;
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = false;
  String? _error;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _groupService = context.read<IGroupService>();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final contactsState = context.read<ContactsBloc>().state;
      List<Contact>? allLoadedContacts;
      if (contactsState is ContactsLoaded) {
        allLoadedContacts = contactsState.allContacts;
      }

      final contacts = await _groupService.getContactsInGroup(
        widget.groupId, 
        allContacts: allLoadedContacts,
      );
      if (!mounted) return;
      
      // Sort contacts based on global settings
      final sortOrder = contactsState is ContactsLoaded ? contactsState.sortOrder : ContactSortOrder.firstName;
      
      contacts.sort((a, b) {
        if (sortOrder == ContactSortOrder.firstName) {
          final nameA = (a.name?.first ?? '').toLowerCase();
          final nameB = (b.name?.first ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        } else {
          final nameA = (a.name?.last ?? '').toLowerCase();
          final nameB = (b.name?.last ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        }
      });

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _expandedIndex = null;
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredContacts = _allContacts.where((contact) {
          return (contact.displayName ?? '').toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Color _getContactColor(String name) {
    final colors = [
      const Color(0xFFD4E4FC),
      const Color(0xFFC2E8FF),
      const Color(0xFFFF7B93),
      const Color(0xFFE5E7EB),
    ];
    return colors[name.hashCode % colors.length];
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
            onPressed: () async {
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
                _loadContacts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contacts added to ${widget.categoryTitle}'),
                      backgroundColor: AppColors.primaryBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _filteredContacts.isEmpty
                        ? const Center(child: Text('No contacts found'))
                        : _buildContactList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredContacts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final contactsState = context.read<ContactsBloc>().state;
        final nameFormat = contactsState is ContactsLoaded ? contactsState.nameFormat : ContactNameFormat.firstLast;

        return ContactListItem(
          index: index,
          contact: contact,
          bgColor: _getContactColor(contact.displayName ?? 'Unknown'),
          nameFormat: nameFormat,
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
            _loadContacts(); // Reload this group's list
          },
          onRemoveFromGroup: () async {
            if (contact.id != null) {
              final voice = context.read<VoiceAssistantService>();
              await _groupService.removeContactFromGroup(contact.id!, widget.groupId);
              if (mounted) {
                voice.speak('Removed ${contact.displayName} from ${widget.categoryTitle}');
                _loadContacts();
              }
            }
          },
        );
      },
    );
  }
}
