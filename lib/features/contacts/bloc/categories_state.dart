import 'package:equatable/equatable.dart';
import 'package:contact_navigator/core/services/group_service.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<Category> allGroups;
  final List<Category> filteredGroups;
  final String searchQuery;

  const CategoriesLoaded({
    required this.allGroups,
    required this.filteredGroups,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [allGroups, filteredGroups, searchQuery];
}

class CategoriesError extends CategoriesState {
  final String message;

  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}
