import 'package:flutter_bloc/flutter_bloc.dart';
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
    emit(GroupContactsLoading());
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
