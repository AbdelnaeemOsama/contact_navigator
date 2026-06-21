import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:contact_navigator/features/contacts/bloc/contacts_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_event.dart';
import 'package:contact_navigator/features/contacts/bloc/contacts_state.dart';
import '../../../helpers/mock_services.dart';

void main() {
  late MockContactService mockContactService;
  late MockSettingsService mockSettings;
  late MockGroupService mockGroupService;
  // Empty stream to avoid platform channel dependency in tests
  late Stream<void> noChanges;

  setUp(() {
    mockContactService = MockContactService();
    mockSettings = MockSettingsService();
    mockGroupService = MockGroupService();
    noChanges = const Stream.empty();

    when(() => mockGroupService.onGroupsChanged).thenAnswer((_) => noChanges);
  });

  group('ContactsBloc', () {
    blocTest<ContactsBloc, ContactsState>(
      'emits [ContactsLoading, ContactsLoaded] on successful load',
      build: () {
        when(() => mockContactService.requestPermission()).thenAnswer((_) async => true);
        when(() => mockContactService.getContacts(
          withProperties: any(named: 'withProperties'),
          withPhoto: any(named: 'withPhoto'),
        )).thenAnswer((_) async => []);
        when(() => mockContactService.getProfile()).thenAnswer((_) async => null);
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(LoadContactsEvent()),
      expect: () => [isA<ContactsLoading>(), isA<ContactsLoaded>()],
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits ContactsPermissionDenied when permission is denied',
      build: () {
        when(() => mockContactService.requestPermission()).thenAnswer((_) async => false);
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(LoadContactsEvent()),
      expect: () => [isA<ContactsLoading>(), isA<ContactsPermissionDenied>()],
    );

    blocTest<ContactsBloc, ContactsState>(
      'emits ContactsError when service throws',
      build: () {
        when(() => mockContactService.requestPermission()).thenAnswer((_) async => true);
        when(() => mockContactService.getContacts(
          withProperties: any(named: 'withProperties'),
          withPhoto: any(named: 'withPhoto'),
        )).thenThrow(Exception('Service failed'));
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(LoadContactsEvent()),
      expect: () => [isA<ContactsLoading>(), isA<ContactsError>()],
    );

    blocTest<ContactsBloc, ContactsState>(
      'silent load keeps ContactsLoaded with isRefreshing',
      build: () {
        when(() => mockContactService.requestPermission()).thenAnswer((_) async => true);
        when(() => mockContactService.getContacts(
          withProperties: any(named: 'withProperties'),
          withPhoto: any(named: 'withPhoto'),
        )).thenAnswer((_) async => []);
        when(() => mockContactService.getProfile()).thenAnswer((_) async => null);
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      seed: () => ContactsLoaded(allContacts: [], filteredContacts: []),
      act: (bloc) => bloc.add(LoadContactsEvent(silent: true)),
      expect: () => [isA<ContactsLoaded>(), isA<ContactsLoaded>()],
    );

    blocTest<ContactsBloc, ContactsState>(
      'search filters by name',
      build: () {
        when(() => mockContactService.requestPermission()).thenAnswer((_) async => true);
        when(() => mockContactService.getContacts(
          withProperties: any(named: 'withProperties'),
          withPhoto: any(named: 'withPhoto'),
        )).thenAnswer((_) async => [
          makeContact(id: '1', firstName: 'John', lastName: 'Doe', displayName: 'John Doe'),
          makeContact(id: '2', firstName: 'Jane', lastName: 'Smith', displayName: 'Jane Smith'),
        ]);
        when(() => mockContactService.getProfile()).thenAnswer((_) async => null);
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      seed: () => ContactsLoaded(
        allContacts: [
          makeContact(id: '1', firstName: 'John', lastName: 'Doe', displayName: 'John Doe'),
          makeContact(id: '2', firstName: 'Jane', lastName: 'Smith', displayName: 'Jane Smith'),
        ],
        filteredContacts: [
          makeContact(id: '1', firstName: 'John', lastName: 'Doe', displayName: 'John Doe'),
          makeContact(id: '2', firstName: 'Jane', lastName: 'Smith', displayName: 'Jane Smith'),
        ],
      ),
      act: (bloc) => bloc.add(SearchContactsEvent('John')),
      expect: () => [isA<ContactsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as ContactsLoaded;
        expect(state.searchQuery, 'John');
        expect(state.filteredContacts.length, 1);
        expect(state.filteredContacts.first.id, '1');
      },
    );

    blocTest<ContactsBloc, ContactsState>(
      'search with empty query returns all contacts',
      build: () {
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      seed: () => ContactsLoaded(
        allContacts: [
          makeContact(id: '1', firstName: 'John', lastName: 'Doe', displayName: 'John Doe'),
          makeContact(id: '2', firstName: 'Jane', lastName: 'Smith', displayName: 'Jane Smith'),
        ],
        filteredContacts: [
          makeContact(id: '1', firstName: 'John', lastName: 'Doe', displayName: 'John Doe'),
        ],
        searchQuery: 'John',
      ),
      act: (bloc) => bloc.add(SearchContactsEvent('')),
      expect: () => [isA<ContactsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as ContactsLoaded;
        expect(state.searchQuery, '');
        expect(state.filteredContacts.length, 2);
      },
    );

    blocTest<ContactsBloc, ContactsState>(
      'clear snackbar clears the message',
      build: () {
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      seed: () => ContactsLoaded(
        allContacts: [],
        filteredContacts: [],
        snackbarMessage: 'Test message',
      ),
      act: (bloc) => bloc.add(ClearContactsSnackBarEvent()),
      expect: () => [isA<ContactsLoaded>()],
      verify: (bloc) {
        expect((bloc.state as ContactsLoaded).snackbarMessage, isNull);
      },
    );

    blocTest<ContactsBloc, ContactsState>(
      'update display settings changes sort order',
      build: () {
        return ContactsBloc(mockContactService, mockSettings, mockGroupService,
            externalChanges: noChanges);
      },
      seed: () => ContactsLoaded(
        allContacts: [
          makeContact(id: '1', firstName: 'Alice', lastName: 'Zeta'),
          makeContact(id: '2', firstName: 'Bob', lastName: 'Alpha'),
        ],
        filteredContacts: [
          makeContact(id: '1', firstName: 'Alice', lastName: 'Zeta'),
          makeContact(id: '2', firstName: 'Bob', lastName: 'Alpha'),
        ],
      ),
      act: (bloc) => bloc.add(UpdateDisplaySettingsEvent(
        sortOrder: ContactSortOrder.lastName,
      )),
      expect: () => [isA<ContactsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as ContactsLoaded;
        expect(state.sortOrder, ContactSortOrder.lastName);
        // After sorting by lastName: Bob Alpha (Alpha) before Alice Zeta (Zeta)
        expect(state.allContacts.first.id, '2');
        expect(state.allContacts.last.id, '1');
      },
    );
  });
}
