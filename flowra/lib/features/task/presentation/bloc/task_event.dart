import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

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
