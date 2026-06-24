import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/group_contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/group_contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/group_contacts_state.dart';
import '../../../helpers/mock_services.dart';

void main() {
  late MockGroupService mockGroupService;
  late MockContactService mockContactService;
  late MockSettingsService mockSettings;
  late Stream<void> noChanges;
  late ContactsBloc contactsBloc;

  setUp(() {
    mockGroupService = MockGroupService();
    mockContactService = MockContactService();
    mockSettings = MockSettingsService();
    noChanges = const Stream.empty();

    when(() => mockGroupService.onGroupsChanged).thenAnswer((_) => noChanges);
    when(() => mockContactService.requestPermission()).thenAnswer((_) async => true);
    when(() => mockContactService.getContacts(
      withProperties: any(named: 'withProperties'),
      withPhoto: any(named: 'withPhoto'),
    )).thenAnswer((_) async => []);
    when(() => mockContactService.getProfile()).thenAnswer((_) async => null);

    contactsBloc = ContactsBloc(mockContactService, mockSettings, mockGroupService,
        externalChanges: noChanges);
  });

  tearDown(() {
    contactsBloc.close();
  });

  group('GroupContactsBloc', () {
    blocTest<GroupContactsBloc, GroupContactsState>(
      'emits GroupContactsLoaded on successful load',
      build: () {
        when(() => mockGroupService.getContactsInGroup(
          any(),
          allContacts: any(named: 'allContacts'),
        )).thenAnswer((_) async => [
          makeContact(id: '1', firstName: 'Alice'),
          makeContact(id: '2', firstName: 'Bob'),
        ]);
        return GroupContactsBloc(mockGroupService, contactsBloc);
      },
      act: (bloc) => bloc.add(LoadGroupContactsEvent('group1')),
      expect: () => [isA<GroupContactsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as GroupContactsLoaded;
        expect(state.contacts.length, 2);
        expect(state.contacts[0].id, '1');
        expect(state.contacts[1].id, '2');
      },
    );

    blocTest<GroupContactsBloc, GroupContactsState>(
      'emits GroupContactsError when service throws',
      build: () {
        when(() => mockGroupService.getContactsInGroup(
          any(),
          allContacts: any(named: 'allContacts'),
        )).thenThrow(Exception('Service failed'));
        return GroupContactsBloc(mockGroupService, contactsBloc);
      },
      act: (bloc) => bloc.add(LoadGroupContactsEvent('group1')),
      expect: () => [isA<GroupContactsError>()],
    );

    blocTest<GroupContactsBloc, GroupContactsState>(
      'search filters by name',
      build: () {
        return GroupContactsBloc(mockGroupService, contactsBloc);
      },
      seed: () => GroupContactsLoaded(
        contacts: [
          makeContact(id: '1', firstName: 'Alice', displayName: 'Alice'),
          makeContact(id: '2', firstName: 'Bob', displayName: 'Bob'),
        ],
        filteredContacts: [
          makeContact(id: '1', firstName: 'Alice', displayName: 'Alice'),
          makeContact(id: '2', firstName: 'Bob', displayName: 'Bob'),
        ],
      ),
      act: (bloc) => bloc.add(SearchGroupContactsEvent('Ali')),
      expect: () => [isA<GroupContactsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as GroupContactsLoaded;
        expect(state.searchQuery, 'ali');
        expect(state.filteredContacts.length, 1);
        expect(state.filteredContacts.first.id, '1');
      },
    );

    blocTest<GroupContactsBloc, GroupContactsState>(
      'search with empty query returns all contacts',
      build: () {
        return GroupContactsBloc(mockGroupService, contactsBloc);
      },
      seed: () => GroupContactsLoaded(
        contacts: [
          makeContact(id: '1', displayName: 'Alice'),
          makeContact(id: '2', displayName: 'Bob'),
        ],
        filteredContacts: [
          makeContact(id: '1', displayName: 'Alice'),
        ],
        searchQuery: 'Ali',
      ),
      act: (bloc) => bloc.add(SearchGroupContactsEvent('')),
      expect: () => [isA<GroupContactsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as GroupContactsLoaded;
        expect(state.searchQuery, '');
        expect(state.filteredContacts.length, 2);
      },
    );

    blocTest<GroupContactsBloc, GroupContactsState>(
      'remove contact from group calls service and reloads',
      build: () {
        when(() => mockGroupService.removeContactFromGroup(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockGroupService.getContactsInGroup(
          any(),
          allContacts: any(named: 'allContacts'),
        )).thenAnswer((_) async => [
          makeContact(id: '2', firstName: 'Bob'),
        ]);
        return GroupContactsBloc(mockGroupService, contactsBloc);
      },
      act: (bloc) => bloc.add(RemoveContactFromGroupEvent('1', 'group1')),
      expect: () => [isA<GroupContactsLoaded>()],
      verify: (bloc) {
        verify(() => mockGroupService.removeContactFromGroup('1', 'group1')).called(1);
        final state = bloc.state as GroupContactsLoaded;
        expect(state.contacts.length, 1);
        expect(state.contacts.first.id, '2');
      },
    );
  });
}
