import 'package:equatable/equatable.dart';

abstract class GroupContactsEvent extends Equatable {
  const GroupContactsEvent();

  @override
  List<Object?> get props => [];
}

class LoadGroupContactsEvent extends GroupContactsEvent {
  final String groupId;

  const LoadGroupContactsEvent(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class SearchGroupContactsEvent extends GroupContactsEvent {
  final String query;

  const SearchGroupContactsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class RemoveContactFromGroupEvent extends GroupContactsEvent {
  final String contactId;
  final String groupId;

  const RemoveContactFromGroupEvent(this.contactId, this.groupId);

  @override
  List<Object?> get props => [contactId, groupId];
}
