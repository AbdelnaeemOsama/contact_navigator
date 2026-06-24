import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/core/services/contact_service.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'package:contact_navigator/core/services/settings_service.dart';
import 'package:contact_navigator/core/utils/text_utils.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final IContactService _contactService;
  final SettingsService _settingsService;
  final IGroupService _groupService;
  StreamSubscription? _contactsSubscription;

  ContactsBloc(
    this._contactService,
    this._settingsService,
    this._groupService, {
    Stream<void>? externalChanges,
  }) : super(ContactsInitial()) {
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

    final source = externalChanges ?? FlutterContacts.onContactChange;
    _contactsSubscription = source.listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        add(const LoadContactsEvent(silent: true));
      });
    });
  }

  Timer? _debounceTimer;
  // close the stream subscription and debounce timer
  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }

  void _onClearSnackBar(
    ClearContactsSnackBarEvent event,
    Emitter<ContactsState> emit,
  ) {
    final s = state;
    if (s is ContactsLoaded) {
      emit(s.copyWith(clearSnack: true));
    }
  }

  void _onClearNavigationAck(
    ClearContactsNavigationAckEvent event,
    Emitter<ContactsState> emit,
  ) {
    final s = state;
    if (s is ContactsLoaded) {
      emit(s.copyWith(clearNav: true));
    }
  }

  Future<void> _onLoadContacts(
    LoadContactsEvent event,
    Emitter<ContactsState> emit,
  ) async {
    final ContactsLoaded? priorLoaded = state is ContactsLoaded
        ? state as ContactsLoaded
        : null;

    try {
      final hasPermission = await _contactService.requestPermission();
      if (!hasPermission) {
        emit(ContactsPermissionDenied());
        return;
      }
      // load contacts with properties and photo
      final contacts = await _contactService.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      final sortOrder =
          priorLoaded?.sortOrder ?? _settingsService.getSortOrder();
      final nameFormat =
          priorLoaded?.nameFormat ?? _settingsService.getNameFormat();
      final query = priorLoaded?.searchQuery ?? '';

      _sortContacts(contacts, sortOrder);
      final filtered = _filterContactsByQuery(contacts, query, sortOrder);
      final favoriteIds = _settingsService.getFavoriteIds().toSet();

      emit(
        ContactsLoaded(
          allContacts: contacts,
          filteredContacts: filtered,
          searchQuery: query,
          sortOrder: sortOrder,
          nameFormat: nameFormat,
          userContact: priorLoaded?.userContact,
          isRefreshing: false,
          snackbarMessage: event.snackbarMessage,
          navigationAck: event.navigationAck,
          favoriteIds: favoriteIds,
        ),
      );

      try {
        final userProfile = await _contactService.getProfile();
        if (!isClosed && state is ContactsLoaded) {
          emit((state as ContactsLoaded).copyWith(userContact: userProfile));
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }
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
    final normalizedQuery = TextUtils.normalise(query);
    final rawQuery = query.replaceAll(RegExp(r'\D'), '');
    final filtered = contacts.where((contact) {
      final displayName = TextUtils.buildDisplayName(
        contact.displayName,
        contact.name?.first,
        contact.name?.last,
      );
      final normalizedName = TextUtils.normalise(displayName);
      final phones = contact.phones
          .map((p) => p.number.replaceAll(RegExp(r'\D'), ''))
          .toList();
      final matchesName = normalizedName.contains(normalizedQuery);
      final matchesPhone =
          rawQuery.isNotEmpty && phones.any((p) => p.contains(rawQuery));
      return matchesName || matchesPhone;
    }).toList();
    _sortContacts(filtered, sortOrder);
    return filtered;
  }

  //to search contacts
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
        final filtered = _filterContactsByQuery(
          currentState.allContacts,
          query,
          currentState.sortOrder,
        );
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

  //to create contact
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
      _emitMutationError(emit, 'Failed to create contact', e);
    }
  }

  //to update contact
  Future<void> _onUpdateContact(
    UpdateContactEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      await _contactService.updateContact(event.contact);

      if (event.contact.id != null) {
        await _groupService.removeContactFromAllGroups(event.contact.id!);
        if (event.groupId != null) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await _groupService.addContactToGroup(
            event.contact.id!,
            event.groupId!,
          );
        }
      }
      //to reload after
      await _reloadAfterMutation(
        emit,
        snackbarMessage: 'Contact updated successfully',
        navigationAck: 'contactSaved',
      );
    } catch (e) {
      _emitMutationError(emit, 'Failed to update contact', e);
    }
  }

  //to delete contact
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
      _emitMutationError(emit, 'Failed to delete contact', e);
    }
  }

  //to toggle favorite
  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      if (event.contact.id != null) {
        await _settingsService.toggleFavorite(event.contact.id!);
      }
      await _reloadAfterMutation(emit);
    } catch (e) {
      _emitMutationError(emit, 'Failed to toggle favorite', e);
    }
  }

  //to add multiple contacts to group
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
      _emitMutationError(emit, 'Failed to add contacts to group', e);
    }
  }

  /// Emits a snackbar error on the current [ContactsLoaded] state instead of
  /// replacing it with [ContactsError], so the user stays on the contacts list.
  void _emitMutationError(Emitter<ContactsState> emit, String label, Object e) {
    final s = state;
    if (s is ContactsLoaded) {
      emit(s.copyWith(snackbarMessage: '$label: $e'));
    } else {
      emit(ContactsError('$label: $e'));
    }
  }

  /// Runs a contacts reload using [LoadContactsEvent] logic with optional UI hints.
  Future<void> _reloadAfterMutation(
    Emitter<ContactsState> emit, {
    String? snackbarMessage,
    String? navigationAck,
  }) async {
    final priorLoaded = state is ContactsLoaded
        ? state as ContactsLoaded
        : null;
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
      final primaryA = _sortPrimaryName(a, sortOrder);
      final primaryB = _sortPrimaryName(b, sortOrder);
      final primaryCompare = primaryA.compareTo(primaryB);
      if (primaryCompare != 0) return primaryCompare;

      return _sortSecondaryName(
        a,
        sortOrder,
      ).compareTo(_sortSecondaryName(b, sortOrder));
    });
  }

  String _sortPrimaryName(Contact contact, ContactSortOrder sortOrder) {
    final displayName = TextUtils.buildDisplayName(
      contact.displayName,
      contact.name?.first,
      contact.name?.last,
    );
    final first = (contact.name?.first ?? '').trim();
    final last = (contact.name?.last ?? '').trim();
    final display = displayName.trim();

    if (sortOrder == ContactSortOrder.firstName) {
      return TextUtils.normalise(first.isNotEmpty ? first : (last.isNotEmpty ? last : display));
    }
    return TextUtils.normalise(last.isNotEmpty ? last : (first.isNotEmpty ? first : display));
  }

  String _sortSecondaryName(Contact contact, ContactSortOrder sortOrder) {
    final first = (contact.name?.first ?? '').trim();
    final last = (contact.name?.last ?? '').trim();

    if (sortOrder == ContactSortOrder.firstName) {
      return TextUtils.normalise(last);
    }
    return TextUtils.normalise(first);
  }
}
