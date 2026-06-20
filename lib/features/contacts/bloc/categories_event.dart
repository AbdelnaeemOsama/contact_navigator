import 'package:equatable/equatable.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoriesEvent extends CategoriesEvent {}

class SearchCategoriesEvent extends CategoriesEvent {
  final String query;

  const SearchCategoriesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class AddCategoryEvent extends CategoriesEvent {
  final String name;

  const AddCategoryEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class DeleteCategoryEvent extends CategoriesEvent {
  final String groupId;

  const DeleteCategoryEvent(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class UpdateCategoryEvent extends CategoriesEvent {
  final String groupId;
  final String newName;

  const UpdateCategoryEvent(this.groupId, this.newName);

  @override
  List<Object?> get props => [groupId, newName];
}
