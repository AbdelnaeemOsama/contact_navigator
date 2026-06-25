import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:contact_navigator/core/services/group_service.dart';
import 'categories_event.dart';
import 'categories_state.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:async';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final IGroupService _groupService;

  CategoriesBloc(
    this._groupService, {
    Stream<void>? externalChanges,
  }) : super(CategoriesInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<SearchCategoriesEvent>(_onSearchCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);

    // Listen for system-wide contact changes to update counts
    final source = externalChanges ?? FlutterContacts.onContactChange;
    _contactsSubscription = source.listen((_) {
      _scheduleReload();
    });

    // Listen for local group changes
    _groupsSubscription = _groupService.onGroupsChanged.listen((_) {
      _scheduleReload();
    });
  }

  StreamSubscription? _contactsSubscription;
  StreamSubscription? _groupsSubscription;
  Timer? _reloadDebounce;

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    _groupsSubscription?.cancel();
    _reloadDebounce?.cancel();
    return super.close();
  }
  //  to reload categories when there is a change in contact list or group list
  void _scheduleReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 600), () {
      add(LoadCategoriesEvent());
    });
  }
 //to load categories
  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<CategoriesState> emit,
  ) async {
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
   //to search categories
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
  //to add category 
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
   //to delete category 
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
  //to update name of category 
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
