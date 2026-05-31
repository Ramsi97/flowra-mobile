import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

enum TaskViewMode { day, week, month }

abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TasksLoaded extends TaskState {
  final List<Task> tasks;
  final TaskViewMode viewMode;
  TasksLoaded(this.tasks, {this.viewMode = TaskViewMode.day});

  @override
  List<Object?> get props => [tasks, viewMode];
}

class TaskOperationSuccess extends TaskState {}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
