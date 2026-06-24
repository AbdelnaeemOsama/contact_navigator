import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:contact_navigator/core/services/group_service.dart';
import 'package:contact_navigator/features/contacts/bloc/categories_bloc.dart';
import 'package:contact_navigator/features/contacts/bloc/categories_event.dart';
import 'package:contact_navigator/features/contacts/bloc/categories_state.dart';
import '../../../helpers/mock_services.dart';

void main() {
  late MockGroupService mockGroupService;
  late Stream<void> noChanges;

  setUp(() {
    mockGroupService = MockGroupService();
    noChanges = const Stream.empty();

    when(() => mockGroupService.onGroupsChanged).thenAnswer((_) => noChanges);
  });

  group('CategoriesBloc', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'emits CategoriesLoaded on successful load',
      build: () {
        when(() => mockGroupService.getGroups(
          withContactCount: any(named: 'withContactCount'),
        )).thenAnswer((_) async => [
          Category(id: '1', name: 'Alpha'),
          Category(id: '2', name: 'Beta'),
        ]);
        return CategoriesBloc(mockGroupService, externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(LoadCategoriesEvent()),
      expect: () => [isA<CategoriesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as CategoriesLoaded;
        expect(state.allGroups.length, 2);
        expect(state.allGroups[0].name, 'Alpha');
        expect(state.allGroups[1].name, 'Beta');
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'emits CategoriesError when service throws',
      build: () {
        when(() => mockGroupService.getGroups(
          withContactCount: any(named: 'withContactCount'),
        )).thenThrow(Exception('Service failed'));
        return CategoriesBloc(mockGroupService, externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(LoadCategoriesEvent()),
      expect: () => [isA<CategoriesError>()],
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'search filters by name',
      build: () {
        return CategoriesBloc(mockGroupService, externalChanges: noChanges);
      },
      seed: () => CategoriesLoaded(
        allGroups: [
          Category(id: '1', name: 'Friends'),
          Category(id: '2', name: 'Family'),
          Category(id: '3', name: 'Work'),
        ],
        filteredGroups: [
          Category(id: '1', name: 'Friends'),
          Category(id: '2', name: 'Family'),
          Category(id: '3', name: 'Work'),
        ],
      ),
      act: (bloc) => bloc.add(SearchCategoriesEvent('Fam')),
      expect: () => [isA<CategoriesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as CategoriesLoaded;
        expect(state.searchQuery, 'fam');
        expect(state.filteredGroups.length, 1);
        expect(state.filteredGroups.first.name, 'Family');
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'search with empty query returns all groups',
      build: () {
        return CategoriesBloc(mockGroupService, externalChanges: noChanges);
      },
      seed: () => CategoriesLoaded(
        allGroups: [
          Category(id: '1', name: 'Friends'),
          Category(id: '2', name: 'Family'),
        ],
        filteredGroups: [
          Category(id: '1', name: 'Friends'),
        ],
        searchQuery: 'Fri',
      ),
      act: (bloc) => bloc.add(SearchCategoriesEvent('')),
      expect: () => [isA<CategoriesLoaded>()],
      verify: (bloc) {
        final state = bloc.state as CategoriesLoaded;
        expect(state.searchQuery, '');
        expect(state.filteredGroups.length, 2);
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'add category calls createGroup and reloads',
      build: () {
        when(() => mockGroupService.createGroup(any())).thenAnswer((_) async =>
          Category(id: '3', name: 'NewCat'));
        when(() => mockGroupService.getGroups(
          withContactCount: any(named: 'withContactCount'),
        )).thenAnswer((_) async => [
          Category(id: '1', name: 'Alpha'),
          Category(id: '3', name: 'NewCat'),
        ]);
        return CategoriesBloc(mockGroupService, externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(AddCategoryEvent('NewCat')),
      expect: () => [isA<CategoriesLoaded>()],
      verify: (bloc) {
        verify(() => mockGroupService.createGroup('NewCat')).called(1);
        final state = bloc.state as CategoriesLoaded;
        expect(state.allGroups.any((g) => g.name == 'NewCat'), isTrue);
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'delete category calls deleteGroup and reloads',
      build: () {
        when(() => mockGroupService.deleteGroup(any())).thenAnswer((_) async {});
        when(() => mockGroupService.getGroups(
          withContactCount: any(named: 'withContactCount'),
        )).thenAnswer((_) async => [
          Category(id: '2', name: 'Beta'),
        ]);
        return CategoriesBloc(mockGroupService, externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(DeleteCategoryEvent('1')),
      expect: () => [isA<CategoriesLoaded>()],
      verify: (bloc) {
        verify(() => mockGroupService.deleteGroup('1')).called(1);
        final state = bloc.state as CategoriesLoaded;
        expect(state.allGroups.length, 1);
        expect(state.allGroups.first.id, '2');
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'update category calls updateGroup and reloads',
      build: () {
        when(() => mockGroupService.updateGroup(any(), any())).thenAnswer((_) async {});
        when(() => mockGroupService.getGroups(
          withContactCount: any(named: 'withContactCount'),
        )).thenAnswer((_) async => [
          Category(id: '1', name: 'Renamed'),
        ]);
        return CategoriesBloc(mockGroupService, externalChanges: noChanges);
      },
      act: (bloc) => bloc.add(UpdateCategoryEvent('1', 'Renamed')),
      expect: () => [isA<CategoriesLoaded>()],
      verify: (bloc) {
        verify(() => mockGroupService.updateGroup('1', 'Renamed')).called(1);
        final state = bloc.state as CategoriesLoaded;
        expect(state.allGroups.first.name, 'Renamed');
      },
    );
  });
}
