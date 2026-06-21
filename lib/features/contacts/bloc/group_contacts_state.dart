import 'package:equatable/equatable.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class GroupContactsState extends Equatable {
  const GroupContactsState();

  @override
  List<Object?> get props => [];
}

class GroupContactsInitial extends GroupContactsState {}

class GroupContactsLoading extends GroupContactsState {}

class GroupContactsLoaded extends GroupContactsState {
  final List<Contact> contacts;
  final List<Contact> filteredContacts;
  final String searchQuery;

  const GroupContactsLoaded({
    required this.contacts,
    required this.filteredContacts,
    this.searchQuery = '',
  });

  GroupContactsLoaded copyWith({
    List<Contact>? contacts,
    List<Contact>? filteredContacts,
    String? searchQuery,
  }) {
    return GroupContactsLoaded(
      contacts: contacts ?? this.contacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [contacts, filteredContacts, searchQuery];
}

class GroupContactsError extends GroupContactsState {
  final String message;

  const GroupContactsError(this.message);

  @override
  List<Object?> get props => [message];
}
