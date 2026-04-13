import 'package:bloc/bloc.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;

  TaskBloc({required this.repository}) : super(TaskInitial()) {
    on<LoadTasksEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await repository.getTasks();
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (tasks) => emit(TasksLoaded(tasks)),
      );
    });

    on<CreateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await repository.createTask(event.task);
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (task) => add(LoadTasksEvent()), // Refresh list
      );
    });

    on<UpdateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await repository.updateTask(event.id, event.updates);
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (task) => add(LoadTasksEvent()), // Refresh list
      );
    });

    on<DeleteTaskEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await repository.deleteTask(event.id);
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (_) => add(LoadTasksEvent()), // Refresh list
      );
    });
  }
}
