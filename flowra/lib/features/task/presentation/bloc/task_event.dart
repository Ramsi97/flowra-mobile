import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';
import 'task_state.dart';

abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTasksEvent extends TaskEvent {}

class CreateTaskEvent extends TaskEvent {
  final Task task;
  CreateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTaskEvent extends TaskEvent {
  final String id;
  final Map<String, dynamic> updates;
  UpdateTaskEvent(this.id, this.updates);

  @override
  List<Object?> get props => [id, updates];
}

class DeleteTaskEvent extends TaskEvent {
  final String id;
  DeleteTaskEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ChangeViewModeEvent extends TaskEvent {
  final TaskViewMode viewMode;
  ChangeViewModeEvent(this.viewMode);

  @override
  List<Object?> get props => [viewMode];
}

class SuggestTasksEvent extends TaskEvent {
  final String description;
  SuggestTasksEvent(this.description);

  @override
  List<Object?> get props => [description];
}

class RefineTasksEvent extends TaskEvent {
  final List<Task> drafts;
  final String instruction;
  RefineTasksEvent(this.drafts, this.instruction);

  @override
  List<Object?> get props => [drafts, instruction];
}

class AcceptSuggestionsEvent extends TaskEvent {
  final List<Task> suggestions;
  AcceptSuggestionsEvent(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}
