import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/services/contact_service.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'package:contact_navigator/core/services/settings_service.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final IContactService _contactService;
  final SettingsService _settingsService;
  final IGroupService _groupService;
  StreamSubscription? _contactsSubscription;

  ContactsBloc(this._contactService, this._settingsService, this._groupService)
      : super(ContactsInitial()) {
    on<LoadContactsEvent>(_onLoadContacts);
    on<ClearContactsSnackBarEvent>(_onClearSnackBar);
    on<ClearContactsNavigationAckEvent>(_onClearNavigationAck);
    on<SearchContactsEvent>(_onSearchContacts);
    on<CreateContactEvent>(_onCreateContact);
    on<UpdateContactEvent>(_onUpdateContact);
    on<DeleteContactEvent>(_onDeleteContact);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<AddMultipleToGroupEvent>(_onAddMultipleToGroup);
    on<UpdateDisplaySettingsEvent>(_onUpdateDisplaySettings);

    _contactsSubscription = FlutterContacts.onContactChange.listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        add(const LoadContactsEvent(silent: true));
      });
    });
  }

  Timer? _debounceTimer;

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }

  void _onClearSnackBar(ClearContactsSnackBarEvent event, Emitter<ContactsState> emit) {
    final s = state;
    if (s is ContactsLoaded) {
      emit(s.copyWith(clearSnack: true));
    }
  }

  void _onClearNavigationAck(ClearContactsNavigationAckEvent event, Emitter<ContactsState> emit) {
    final s = state;
    if (s is ContactsLoaded) {
      emit(s.copyWith(clearNav: true));
    }
  }

  Future<void> _onLoadContacts(
    LoadContactsEvent event,
    Emitter<ContactsState> emit,
  ) async {
    final ContactsLoaded? priorLoaded = state is ContactsLoaded ? state as ContactsLoaded : null;

    if (priorLoaded != null && event.silent) {
      emit(priorLoaded.copyWith(isRefreshing: true));
    } else {
      emit(ContactsLoading());
    }

    try {
      final hasPermission = await _contactService.requestPermission();
      if (!hasPermission) {
        emit(ContactsPermissionDenied());
        return;
      }

      final contacts = await _contactService.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      Contact? userProfile;
      try {
        userProfile = await _contactService.getProfile();
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }

      final sortOrder = priorLoaded?.sortOrder ?? _settingsService.getSortOrder();
      final nameFormat = priorLoaded?.nameFormat ?? _settingsService.getNameFormat();
      final query = priorLoaded?.searchQuery ?? '';

      _sortContacts(contacts, sortOrder);
      final filtered = _filterContactsByQuery(contacts, query, sortOrder);

      emit(
        ContactsLoaded(
          allContacts: contacts,
          filteredContacts: filtered,
          searchQuery: query,
          sortOrder: sortOrder,
          nameFormat: nameFormat,
          userContact: userProfile,
          isRefreshing: false,
          snackbarMessage: event.snackbarMessage,
          navigationAck: event.navigationAck,
        ),
      );
    } catch (e) {
      emit(ContactsError(e.toString()));
    }
  }

  List<Contact> _filterContactsByQuery(
    List<Contact> contacts,
    String query,
    ContactSortOrder sortOrder,
  ) {
    if (query.isEmpty) {
      return List<Contact>.from(contacts);
    }
    final lowerQuery = query.toLowerCase();
    final rawQuery = query.replaceAll(RegExp(r'\D'), '');
    final filtered = contacts.where((contact) {
      final name = (contact.displayName ?? '').toLowerCase();
      final phones = contact.phones
          .map((p) => p.number.replaceAll(RegExp(r'\D'), ''))
          .toList();
      final matchesName = name.contains(lowerQuery);
      final matchesPhone =
          rawQuery.isNotEmpty && phones.any((p) => p.contains(rawQuery));
      return matchesName || matchesPhone;
    }).toList();
    _sortContacts(filtered, sortOrder);
    return filtered;
  }

  Future<void> _onSearchContacts(
    SearchContactsEvent event,
    Emitter<ContactsState> emit,
  ) async {
    if (state is ContactsLoaded) {
      final currentState = state as ContactsLoaded;
      final query = event.query;

      if (query.isEmpty) {
        emit(
          currentState.copyWith(
            filteredContacts: currentState.allContacts,
            searchQuery: '',
            clearSnack: true,
            clearNav: true,
          ),
        );
      } else {
        final filtered = _filterContactsByQuery(currentState.allContacts, query, currentState.sortOrder);
        emit(
          currentState.copyWith(
            filteredContacts: filtered,
            searchQuery: query,
            clearSnack: true,
            clearNav: true,
          ),
        );
      }
    }
  }

  Future<void> _onCreateContact(
    CreateContactEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      final createdId = await _contactService.createContact(
        firstName: event.firstName,
        lastName: event.lastName,
        phones: event.phones,
        emails: event.emails,
        addresses: event.addresses,
        websites: event.websites,
        notes: event.notes,
        photo: event.photo,
        groupId: null,
      );

      if (event.groupId != null) {
        await _groupService.addContactToGroup(createdId, event.groupId!);
      }

      await _reloadAfterMutation(
        emit,
        snackbarMessage: 'Contact created successfully',
        navigationAck: 'contactSaved',
      );
    } catch (e) {
      emit(ContactsError('Failed to create contact: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateContact(
    UpdateContactEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      await _contactService.updateContact(event.contact);

      if (event.groupId != null && event.contact.id != null) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await _groupService.addContactToGroup(event.contact.id!, event.groupId!);
      }

      await _reloadAfterMutation(
        emit,
        snackbarMessage: 'Contact updated successfully',
        navigationAck: 'contactSaved',
      );
    } catch (e) {
      emit(ContactsError('Failed to update contact: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteContact(
    DeleteContactEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      await _contactService.deleteContact(event.contactId);
      await _reloadAfterMutation(
        emit,
        snackbarMessage: 'Contact deleted successfully',
      );
    } catch (e) {
      emit(ContactsError('Failed to delete contact: ${e.toString()}'));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      await _contactService.toggleFavorite(event.contact);
      await _reloadAfterMutation(emit);
    } catch (e) {
      emit(ContactsError('Failed to toggle favorite: ${e.toString()}'));
    }
  }

  Future<void> _onAddMultipleToGroup(
    AddMultipleToGroupEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      for (final id in event.contactIds) {
        await _groupService.addContactToGroup(id, event.groupId);
      }
      await _reloadAfterMutation(
        emit,
        snackbarMessage: 'Contacts added to group successfully',
        navigationAck: 'selectionDone',
      );
    } catch (e) {
      emit(ContactsError('Failed to add contacts to group: ${e.toString()}'));
    }
  }

  /// Runs a contacts reload using [LoadContactsEvent] logic with optional UI hints.
  Future<void> _reloadAfterMutation(
    Emitter<ContactsState> emit, {
    String? snackbarMessage,
    String? navigationAck,
  }) async {
    final priorLoaded = state is ContactsLoaded ? state as ContactsLoaded : null;
    final silent = priorLoaded != null;
    await _onLoadContacts(
      LoadContactsEvent(
        silent: silent,
        snackbarMessage: snackbarMessage,
        navigationAck: navigationAck,
      ),
      emit,
    );
  }

  void _onUpdateDisplaySettings(
    UpdateDisplaySettingsEvent event,
    Emitter<ContactsState> emit,
  ) {
    if (state is ContactsLoaded) {
      final currentState = state as ContactsLoaded;
      final newSortOrder = event.sortOrder ?? currentState.sortOrder;
      final newNameFormat = event.nameFormat ?? currentState.nameFormat;

      if (event.sortOrder != null) {
        _settingsService.setSortOrder(newSortOrder);
      }
      if (event.nameFormat != null) {
        _settingsService.setNameFormat(newNameFormat);
      }

      final allSorted = List<Contact>.from(currentState.allContacts);
      _sortContacts(allSorted, newSortOrder);

      final filteredSorted = _filterContactsByQuery(
        allSorted,
        currentState.searchQuery,
        newSortOrder,
      );

      emit(
        currentState.copyWith(
          allContacts: allSorted,
          filteredContacts: filteredSorted,
          sortOrder: newSortOrder,
          nameFormat: newNameFormat,
        ),
      );
    }
  }

  void _sortContacts(List<Contact> contacts, ContactSortOrder sortOrder) {
    contacts.sort((a, b) {
      if (sortOrder == ContactSortOrder.firstName) {
        final nameA = (a.name?.first ?? '').toLowerCase();
        final nameB = (b.name?.first ?? '').toLowerCase();
        if (nameA == nameB) {
          return (a.name?.last ?? '').toLowerCase().compareTo(
                (b.name?.last ?? '').toLowerCase(),
              );
        }
        return nameA.compareTo(nameB);
      } else {
        final nameA = (a.name?.last ?? '').toLowerCase();
        final nameB = (b.name?.last ?? '').toLowerCase();
        if (nameA == nameB) {
          return (a.name?.first ?? '').toLowerCase().compareTo(
                (b.name?.first ?? '').toLowerCase(),
              );
        }
        return nameA.compareTo(nameB);
      }
    });
  }
}
