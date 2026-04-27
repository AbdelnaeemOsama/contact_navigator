import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/services/contact_service.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final IContactService _contactService;

  ContactsBloc(this._contactService) : super(ContactsInitial()) {
    on<LoadContactsEvent>(_onLoadContacts);
    on<SearchContactsEvent>(_onSearchContacts);
  }

  Future<void> _onLoadContacts(LoadContactsEvent event, Emitter<ContactsState> emit) async {
    emit(ContactsLoading());
    try {
      final hasPermission = await _contactService.requestPermission();
      if (!hasPermission) {
        emit(ContactsPermissionDenied());
        return;
      }
      
      final contacts = await _contactService.getContacts(withProperties: true, withPhoto: true);
      // Sort contacts alphabetically
      contacts.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));
      
      emit(ContactsLoaded(
        allContacts: contacts,
        filteredContacts: contacts,
      ));
    } catch (e) {
      emit(ContactsError(e.toString()));
    }
  }

  void _onSearchContacts(SearchContactsEvent event, Emitter<ContactsState> emit) {
    if (state is ContactsLoaded) {
      final currentState = state as ContactsLoaded;
      final query = event.query.toLowerCase();
      
      if (query.isEmpty) {
        emit(ContactsLoaded(
          allContacts: currentState.allContacts,
          filteredContacts: currentState.allContacts,
          searchQuery: query,
        ));
      } else {
        final filtered = currentState.allContacts.where((contact) {
          final matchesName = (contact.displayName ?? '').toLowerCase().contains(query);
          final matchesPhone = contact.phones.any((phone) => phone.number.contains(query));
          return matchesName || matchesPhone;
        }).toList();
        
        emit(ContactsLoaded(
          allContacts: currentState.allContacts,
          filteredContacts: filtered,
          searchQuery: query,
        ));
      }
    }
  }
}
