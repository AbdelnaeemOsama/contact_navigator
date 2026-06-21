import 'package:equatable/equatable.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

enum ContactSortOrder { firstName, lastName }
enum ContactNameFormat { firstLast, lastFirst }

abstract class ContactsState extends Equatable {
  const ContactsState();

  @override
  List<Object?> get props => [];
}

class ContactsInitial extends ContactsState {}

class ContactsLoading extends ContactsState {}

class ContactsLoaded extends ContactsState {
  final List<Contact> allContacts;
  final List<Contact> filteredContacts;
  final String searchQuery;
  final ContactSortOrder sortOrder;
  final ContactNameFormat nameFormat;
  final Contact? userContact;
  final bool isRefreshing;
  final String? snackbarMessage;
  final String? navigationAck;
  final Set<String> favoriteIds;

  const ContactsLoaded({
    required this.allContacts,
    required this.filteredContacts,
    this.searchQuery = '',
    this.sortOrder = ContactSortOrder.firstName,
    this.nameFormat = ContactNameFormat.firstLast,
    this.userContact,
    this.isRefreshing = false,
    this.snackbarMessage,
    this.navigationAck,
    this.favoriteIds = const {},
  });

  ContactsLoaded copyWith({
    List<Contact>? allContacts,
    List<Contact>? filteredContacts,
    String? searchQuery,
    ContactSortOrder? sortOrder,
    ContactNameFormat? nameFormat,
    Contact? userContact,
    bool? isRefreshing,
    String? snackbarMessage,
    String? navigationAck,
    Set<String>? favoriteIds,
    bool clearSnack = false,
    bool clearNav = false,
  }) {
    return ContactsLoaded(
      allContacts: allContacts ?? this.allContacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
      nameFormat: nameFormat ?? this.nameFormat,
      userContact: userContact ?? this.userContact,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      snackbarMessage: clearSnack ? null : (snackbarMessage ?? this.snackbarMessage),
      navigationAck: clearNav ? null : (navigationAck ?? this.navigationAck),
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }

  @override
  List<Object?> get props => [
        allContacts,
        filteredContacts,
        searchQuery,
        sortOrder,
        nameFormat,
        userContact,
        isRefreshing,
        snackbarMessage,
        navigationAck,
        favoriteIds,
      ];
}

class ContactsError extends ContactsState {
  final String message;

  const ContactsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ContactsPermissionDenied extends ContactsState {}
