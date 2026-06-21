import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'package:contact_navigator/features/contacts/widgets/contact_list_item.dart';
import 'package:latlong2/latlong.dart';

class ContactsSearchPage extends StatefulWidget {
  final void Function(LatLng location)? onNavigateToMap;

  const ContactsSearchPage({
    super.key,
    this.onNavigateToMap,
  });

  @override
  State<ContactsSearchPage> createState() => _ContactsSearchPageState();
}

class _ContactsSearchPageState extends State<ContactsSearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _searchDebounce;
  int? _expandedIndex;

  static const _lightBlue = Color(0xFF33A1E5);

  @override
  void initState() {
    super.initState();
    final blocState = context.read<ContactsBloc>().state;
    final initialQuery =
        blocState is ContactsLoaded ? blocState.searchQuery : '';
    _controller = TextEditingController(text: initialQuery);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (initialQuery.isNotEmpty) {
        context.read<ContactsBloc>().add(SearchContactsEvent(initialQuery));
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _expandedIndex = null);
      context.read<ContactsBloc>().add(SearchContactsEvent(query));
    });
  }

  void _closeSearch() {
    context.read<ContactsBloc>().add(const SearchContactsEvent(''));
    Navigator.pop(context);
  }

  Color _contactColor(String name) {
    final hash = name.isNotEmpty ? name.codeUnitAt(0) : 0;
    return AppColors.contactAvatarColors[hash % AppColors.contactAvatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ContactsBloc>().add(const SearchContactsEvent(''));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _closeSearch,
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textBlue),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, child) {
                          return Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Directionality(
                                    textDirection: TextUtils.getTextDirection(value.text),
                                    child: TextField(
                                      controller: _controller,
                                      focusNode: _focusNode,
                                      autofocus: true,
                                      onChanged: _onQueryChanged,
                                      textInputAction: TextInputAction.search,
                                      decoration: const InputDecoration(
                                        hintText: 'Search contacts',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (value.text.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _controller.clear();
                                    _onQueryChanged('');
                                  },
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: _lightBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<ContactsBloc, ContactsState>(
                  buildWhen: (previous, current) {
                    if (previous.runtimeType != current.runtimeType) return true;
                    if (current is ContactsLoaded && previous is ContactsLoaded) {
                      return previous.filteredContacts != current.filteredContacts ||
                          previous.favoriteIds != current.favoriteIds ||
                          previous.nameFormat != current.nameFormat;
                    }
                    return true;
                  },
                  builder: (context, state) {
                    if (state is! ContactsLoaded) {
                      return const SizedBox.shrink();
                    }

                    final query = state.searchQuery.trim();
                    if (query.isEmpty) {
                      return Center(
                        child: Text(
                          'Type a name or phone number',
                          style: TextStyle(
                            color: AppColors.textBlue.withValues(alpha: 0.55),
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    if (state.filteredContacts.isEmpty) {
                      return Center(
                        child: Text(
                          'No contacts found',
                          style: TextStyle(
                            color: AppColors.textBlue.withValues(alpha: 0.55),
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      cacheExtent: 400,
                      itemCount: state.filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = state.filteredContacts[index];
                        return ContactListItem(
                          key: ValueKey(contact.id ?? 'search_$index'),
                          index: index,
                          contact: contact,
                          bgColor: _contactColor(contact.displayName ?? ''),
                          nameFormat: state.nameFormat,
                          isFavorite: state.favoriteIds.contains(contact.id),
                          isExpanded: _expandedIndex == index,
                          onTap: () {
                            setState(() {
                              _expandedIndex = _expandedIndex == index ? null : index;
                            });
                          },
                          onNavigateToMap: widget.onNavigateToMap,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
