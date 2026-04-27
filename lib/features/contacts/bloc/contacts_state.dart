import 'package:equatable/equatable.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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

  const ContactsLoaded({
    required this.allContacts,
    required this.filteredContacts,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [allContacts, filteredContacts, searchQuery];
}

class ContactsError extends ContactsState {
  final String message;

  const ContactsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ContactsPermissionDenied extends ContactsState {}
