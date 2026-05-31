import 'package:bloc/bloc.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;

  TaskBloc({required this.repository}) : super(TaskInitial()) {
    on<LoadTasksEvent>((event, emit) async {
      final currentMode = state is TasksLoaded ? (state as TasksLoaded).viewMode : TaskViewMode.day;
      emit(TaskLoading());
      final result = await repository.getTasks();
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (tasks) => emit(TasksLoaded(tasks, viewMode: currentMode)),
      );
    });

    on<ChangeViewModeEvent>((event, emit) {
      if (state is TasksLoaded) {
        final currentState = state as TasksLoaded;
        emit(TasksLoaded(currentState.tasks, viewMode: event.viewMode));
      }
    });

    on<CreateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await repository.createTask(event.task);
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (task) => add(LoadTasksEvent()),
      );
    });

    on<UpdateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await repository.updateTask(event.id, event.updates);
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (task) => add(LoadTasksEvent()),
      );
    });

    on<DeleteTaskEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await repository.deleteTask(event.id);
      result.fold(
        (failure) => emit(TaskError(failure.toString())),
        (_) => add(LoadTasksEvent()),
      );
    });
  }
}
