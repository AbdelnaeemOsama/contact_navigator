import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import 'group_contacts_event.dart';
import 'group_contacts_state.dart';

class GroupContactsBloc extends Bloc<GroupContactsEvent, GroupContactsState> {
  final IGroupService _groupService;
  final ContactsBloc _contactsBloc;

  GroupContactsBloc(this._groupService, this._contactsBloc)
      : super(GroupContactsInitial()) {
    on<LoadGroupContactsEvent>(_onLoad);
    on<SearchGroupContactsEvent>(_onSearch);
    on<RemoveContactFromGroupEvent>(_onRemove);
  }

  Future<void> _onLoad(
    LoadGroupContactsEvent event,
    Emitter<GroupContactsState> emit,
  ) async {
    try {
      final contactsState = _contactsBloc.state;
      final allLoaded = contactsState is ContactsLoaded ? contactsState.allContacts : null;

      final contacts = await _groupService.getContactsInGroup(
        event.groupId,
        allContacts: allLoaded,
      );

      final sortOrder = contactsState is ContactsLoaded
          ? contactsState.sortOrder
          : ContactSortOrder.firstName;

      contacts.sort((a, b) {
        String primary(Contact c) {
          final first = (c.name?.first ?? '').trim();
          final last = (c.name?.last ?? '').trim();
          final display = (c.displayName ?? '').trim();
          if (sortOrder == ContactSortOrder.firstName) {
            return (first.isNotEmpty ? first : (last.isNotEmpty ? last : display))
                .toLowerCase();
          }
          return (last.isNotEmpty ? last : (first.isNotEmpty ? first : display))
              .toLowerCase();
        }

        final cmp = primary(a).compareTo(primary(b));
        if (cmp != 0) return cmp;

        final secondaryA = sortOrder == ContactSortOrder.firstName
            ? (a.name?.last ?? '').toLowerCase()
            : (a.name?.first ?? '').toLowerCase();
        final secondaryB = sortOrder == ContactSortOrder.firstName
            ? (b.name?.last ?? '').toLowerCase()
            : (b.name?.first ?? '').toLowerCase();
        return secondaryA.compareTo(secondaryB);
      });

      emit(GroupContactsLoaded(
        contacts: contacts,
        filteredContacts: contacts,
      ));
    } catch (e) {
      emit(GroupContactsError(e.toString()));
    }
  }

  void _onSearch(
    SearchGroupContactsEvent event,
    Emitter<GroupContactsState> emit,
  ) {
    if (state is GroupContactsLoaded) {
      final current = state as GroupContactsLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(current.copyWith(
          filteredContacts: current.contacts,
          searchQuery: '',
        ));
        return;
      }

      final filtered = current.contacts.where((c) {
        return (c.displayName ?? '').toLowerCase().contains(query);
      }).toList();

      emit(current.copyWith(
        filteredContacts: filtered,
        searchQuery: query,
      ));
    }
  }

  Future<void> _onRemove(
    RemoveContactFromGroupEvent event,
    Emitter<GroupContactsState> emit,
  ) async {
    try {
      await _groupService.removeContactFromGroup(event.contactId, event.groupId);
      add(LoadGroupContactsEvent(event.groupId));
    } catch (e) {
      emit(GroupContactsError('Failed to remove contact: $e'));
    }
  }
}
