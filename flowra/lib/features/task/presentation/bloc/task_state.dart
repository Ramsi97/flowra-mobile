import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

enum TaskViewMode { day, week, month }

abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {
  /// When [preservedTasks] is set, the UI can show a list + overlay spinner
  /// rather than blanking the whole screen during create/update/delete.
  final List<Task>? preservedTasks;
  final TaskViewMode viewMode;

  TaskLoading({this.preservedTasks, this.viewMode = TaskViewMode.day});

  @override
  List<Object?> get props => [preservedTasks, viewMode];
}

class TasksLoaded extends TaskState {
  final List<Task> tasks;
  final TaskViewMode viewMode;
  TasksLoaded(this.tasks, {this.viewMode = TaskViewMode.day});

  @override
  List<Object?> get props => [tasks, viewMode];
}

/// Emitted after create / update / delete succeeds before reloading the list.
class TaskOperationSuccess extends TaskState {
  final String message;
  TaskOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emitted after AI suggest/refine returns results.
class TaskSuggestionsLoaded extends TaskState {
  final List<Task> suggestions;
  TaskSuggestionsLoaded(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
