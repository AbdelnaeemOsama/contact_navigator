import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/contacts_bloc.dart';
import 'bloc/contacts_event.dart';
import 'bloc/contacts_state.dart';
import 'bloc/categories_bloc.dart';
import 'bloc/categories_event.dart';

class SelectContactsPage extends StatefulWidget {
  final String groupId;
  final String categoryTitle;

  const SelectContactsPage({
    super.key,
    required this.groupId,
    required this.categoryTitle,
  });

  @override
  State<SelectContactsPage> createState() => _SelectContactsPageState();
}

class _SelectContactsPageState extends State<SelectContactsPage> {
  final Set<String> _selectedContactIds = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure all contacts are loaded
    context.read<ContactsBloc>().add(LoadContactsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    context.read<ContactsBloc>().add(SearchContactsEvent(query));
  }

  Future<void> _addSelectedContacts() async {
    if (_selectedContactIds.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      context.read<ContactsBloc>().add(
        AddMultipleToGroupEvent(_selectedContactIds.toList(), widget.groupId),
      );
      
      // Refresh categories to update contact counts
      context.read<CategoriesBloc>().add(LoadCategoriesEvent());
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add contacts to category.')),
        );
      }
    }
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
          icon: const Icon(Icons.close, color: AppColors.textBlue, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add to ${widget.categoryTitle}',
          style: const TextStyle(
            color: AppColors.textBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectedContactIds.isNotEmpty)
            TextButton(
              onPressed: _isSubmitting ? null : _addSelectedContacts,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: lightBlue,
                      ),
                    )
                  : const Text(
                      'DONE',
                      style: TextStyle(
                        color: lightBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
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
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Contact List
          Expanded(
            child: BlocListener<ContactsBloc, ContactsState>(
              listenWhen: (previous, current) {
                if (current is! ContactsLoaded) return false;
                if (current.navigationAck != 'selectionDone') return false;
                if (previous is! ContactsLoaded) return true;
                return previous.navigationAck != current.navigationAck;
              },
              listener: (context, state) {
                context.read<ContactsBloc>().add(const ClearContactsNavigationAckEvent());
                Navigator.pop(context, true);
              },
              child: BlocListener<ContactsBloc, ContactsState>(
                listenWhen: (previous, current) => current is ContactsError,
                listener: (context, state) {
                  if (state is ContactsError) {
                    setState(() => _isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                child: BlocBuilder<ContactsBloc, ContactsState>(
                  builder: (context, state) {
                  if (state is ContactsLoaded) {
                    final contacts = state.filteredContacts;
                    if (contacts.isEmpty) {
                      return const Center(child: Text('No contacts found'));
                    }
                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final isSelected = _selectedContactIds.contains(contact.id);
                        final name = contact.displayName ?? 'Unknown';
                        
                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedContactIds.remove(contact.id);
                              } else {
                                if (contact.id != null) {
                                  _selectedContactIds.add(contact.id!);
                                }
                              }
                            });
                          },
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? lightBlue : Colors.grey.shade200,
                            child: isSelected 
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                          ),
                          title: Directionality(
                            textDirection: TextUtils.getTextDirection(name),
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textBlue,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            contact.phones.isNotEmpty ? contact.phones.first.number : 'No number',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  if (contact.id != null) _selectedContactIds.add(contact.id!);
                                } else {
                                  _selectedContactIds.remove(contact.id);
                                }
                              });
                            },
                            activeColor: lightBlue,
                            shape: const CircleBorder(),
                          ),
                        );
                      },
                    );
                  }
                  if (state is ContactsLoading || state is ContactsInitial) {
                    return const SizedBox.shrink();
                  }
                  return const Center(child: Text('Failed to load contacts'));
                },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
