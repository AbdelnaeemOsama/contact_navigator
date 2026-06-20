import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'categories_event.dart';
import 'categories_state.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:async';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final IGroupService _groupService;

  CategoriesBloc(this._groupService) : super(CategoriesInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<SearchCategoriesEvent>(_onSearchCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);

    // Listen for system-wide contact changes to update counts
    _contactsSubscription = FlutterContacts.onContactChange.listen((_) {
      add(LoadCategoriesEvent());
    });

    // Listen for local group changes
    _groupsSubscription = _groupService.onGroupsChanged.listen((_) {
      add(LoadCategoriesEvent());
    });
  }

  StreamSubscription? _contactsSubscription;
  StreamSubscription? _groupsSubscription;

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    _groupsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    try {
      final groups = await _groupService.getGroups(withContactCount: true);
      groups.sort((a, b) => a.name.compareTo(b.name));

      emit(CategoriesLoaded(
        allGroups: groups,
        filteredGroups: groups,
      ));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  void _onSearchCategories(
    SearchCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) {
    if (state is CategoriesLoaded) {
      final currentState = state as CategoriesLoaded;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(CategoriesLoaded(
          allGroups: currentState.allGroups,
          filteredGroups: currentState.allGroups,
          searchQuery: '',
        ));
      } else {
        final filtered = currentState.allGroups
            .where((group) => group.name.toLowerCase().contains(query))
            .toList();

        emit(CategoriesLoaded(
          allGroups: currentState.allGroups,
          filteredGroups: filtered,
          searchQuery: query,
        ));
      }
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await _groupService.createGroup(event.name);
      // Reload after creating
      add(LoadCategoriesEvent());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await _groupService.deleteGroup(event.groupId);
      // Reload after deleting
      add(LoadCategoriesEvent());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoriesState> emit,
  ) async {
    try {
      await _groupService.updateGroup(event.groupId, event.newName);
      // Reload after updating
      add(LoadCategoriesEvent());
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}
