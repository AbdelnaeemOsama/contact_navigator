import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';

abstract class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class LoadContactsEvent extends ContactsEvent {
  /// When true and the current state is [ContactsLoaded], skips the full-screen
  /// loading state and shows an inline refresh instead.
  final bool silent;
  final String? snackbarMessage;
  final String? navigationAck;

  const LoadContactsEvent({
    this.silent = false,
    this.snackbarMessage,
    this.navigationAck,
  });

  @override
  List<Object?> get props => [silent, snackbarMessage, navigationAck];
}

class ClearContactsSnackBarEvent extends ContactsEvent {
  const ClearContactsSnackBarEvent();
}

class ClearContactsNavigationAckEvent extends ContactsEvent {
  const ClearContactsNavigationAckEvent();
}

class SearchContactsEvent extends ContactsEvent {
  final String query;

  const SearchContactsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateContactEvent extends ContactsEvent {
  final String firstName;
  final String lastName;
  final List<Phone> phones;
  final List<Email> emails;
  final List<Address> addresses;
  final List<Website> websites;
  final String? notes;
  final Uint8List? photo;
  final String? groupId;

  const CreateContactEvent({
    required this.firstName,
    required this.lastName,
    required this.phones,
    this.emails = const [],
    this.addresses = const [],
    this.websites = const [],
    this.notes,
    this.photo,
    this.groupId,
  });

  @override
  List<Object?> get props => [firstName, lastName, phones, emails, addresses, websites, notes, photo, groupId];
}

class UpdateContactEvent extends ContactsEvent {
  final Contact contact;
  final String? groupId;

  const UpdateContactEvent(this.contact, {this.groupId});

  @override
  List<Object?> get props => [contact, groupId];
}

class DeleteContactEvent extends ContactsEvent {
  final String contactId;

  const DeleteContactEvent(this.contactId);

  @override
  List<Object?> get props => [contactId];
}

class ToggleFavoriteEvent extends ContactsEvent {
  final Contact contact;

  const ToggleFavoriteEvent(this.contact);

  @override
  List<Object?> get props => [contact];
}

class AddMultipleToGroupEvent extends ContactsEvent {
  final List<String> contactIds;
  final String groupId;

  const AddMultipleToGroupEvent(this.contactIds, this.groupId);

  @override
  List<Object?> get props => [contactIds, groupId];
}

class UpdateDisplaySettingsEvent extends ContactsEvent {
  final ContactSortOrder? sortOrder;
  final ContactNameFormat? nameFormat;

  const UpdateDisplaySettingsEvent({this.sortOrder, this.nameFormat});

  @override
  List<Object?> get props => [sortOrder, nameFormat];
}
