import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart' hide Task;
import '../../domain/usecase/get_tasks_usecase.dart';
import '../../domain/usecase/create_task_usecase.dart';
import '../../domain/usecase/update_task_usecase.dart';
import '../../domain/usecase/delete_task_usecase.dart';
import '../../domain/usecase/suggest_tasks_usecase.dart';
import '../../domain/usecase/refine_tasks_usecase.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final SuggestTasksUseCase suggestTasksUseCase;
  final RefineTasksUseCase refineTasksUseCase;

  TaskBloc({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.suggestTasksUseCase,
    required this.refineTasksUseCase,
  }) : super(TaskInitial()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<ChangeViewModeEvent>(_onChangeViewMode);
    on<CreateTaskEvent>(_onCreateTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<SuggestTasksEvent>(_onSuggestTasks);
    on<RefineTasksEvent>(_onRefineTasks);
    on<AcceptSuggestionsEvent>(_onAcceptSuggestions);
  }

  /// Gets current view mode from state, falling back to day.
  TaskViewMode get _currentViewMode {
    if (state is TasksLoaded) return (state as TasksLoaded).viewMode;
    if (state is TaskLoading) return (state as TaskLoading).viewMode;
    return TaskViewMode.day;
  }

  /// Gets current task list from state (null if no list yet).
  List? get _currentTasks {
    if (state is TasksLoaded) return (state as TasksLoaded).tasks;
    if (state is TaskLoading) return (state as TaskLoading).preservedTasks;
    return null;
  }

  Future<void> _onLoadTasks(LoadTasksEvent event, Emitter<TaskState> emit) async {
    emit(TaskLoading(viewMode: _currentViewMode));
    final result = await getTasksUseCase();
    result.fold(
      (failure) => emit(TaskError(failure.toString())),
      (tasks) => emit(TasksLoaded(tasks, viewMode: _currentViewMode)),
    );
  }

  void _onChangeViewMode(ChangeViewModeEvent event, Emitter<TaskState> emit) {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      emit(TasksLoaded(currentState.tasks, viewMode: event.viewMode));
    }
  }

  Future<void> _onCreateTask(CreateTaskEvent event, Emitter<TaskState> emit) async {
    // Preserve current list so UI stays visible while creating
    final preserved = _currentTasks;
    final mode = _currentViewMode;
    emit(TaskLoading(preservedTasks: preserved?.cast(), viewMode: mode));
    final result = await createTaskUseCase(event.task);
    result.fold(
      (failure) {
        // Restore list on failure, emit error so UI can show snackbar
        if (preserved != null) {
          emit(TasksLoaded(preserved.cast(), viewMode: mode));
        }
        emit(TaskError(failure.toString()));
      },
      (task) {
        emit(TaskOperationSuccess('Task created successfully'));
        add(LoadTasksEvent());
      },
    );
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    final preserved = _currentTasks;
    final mode = _currentViewMode;
    emit(TaskLoading(preservedTasks: preserved?.cast(), viewMode: mode));
    final result = await updateTaskUseCase(event.id, event.updates);
    result.fold(
      (failure) {
        if (preserved != null) {
          emit(TasksLoaded(preserved.cast(), viewMode: mode));
        }
        emit(TaskError(failure.toString()));
      },
      (task) {
        emit(TaskOperationSuccess('Task updated'));
        add(LoadTasksEvent());
      },
    );
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TaskState> emit) async {
    final preserved = _currentTasks;
    final mode = _currentViewMode;
    emit(TaskLoading(preservedTasks: preserved?.cast(), viewMode: mode));
    final result = await deleteTaskUseCase(event.id);
    result.fold(
      (failure) {
        if (preserved != null) {
          emit(TasksLoaded(preserved.cast(), viewMode: mode));
        }
        emit(TaskError(failure.toString()));
      },
      (_) {
        emit(TaskOperationSuccess('Task deleted'));
        add(LoadTasksEvent());
      },
    );
  }

  Future<void> _onSuggestTasks(SuggestTasksEvent event, Emitter<TaskState> emit) async {
    emit(TaskLoading(preservedTasks: _currentTasks?.cast(), viewMode: _currentViewMode));
    final result = await suggestTasksUseCase(event.description);
    result.fold(
      (failure) => emit(TaskError(failure.toString())),
      (suggestions) => emit(TaskSuggestionsLoaded(suggestions)),
    );
  }

  Future<void> _onRefineTasks(RefineTasksEvent event, Emitter<TaskState> emit) async {
    emit(TaskLoading(preservedTasks: _currentTasks?.cast(), viewMode: _currentViewMode));
    final result = await refineTasksUseCase(event.drafts, event.instruction);
    result.fold(
      (failure) => emit(TaskError(failure.toString())),
      (refined) => emit(TaskSuggestionsLoaded(refined)),
    );
  }

  Future<void> _onAcceptSuggestions(AcceptSuggestionsEvent event, Emitter<TaskState> emit) async {
    emit(TaskLoading(preservedTasks: _currentTasks?.cast(), viewMode: _currentViewMode));

    bool anySuccess = false;
    for (final task in event.suggestions) {
      final result = await createTaskUseCase(task);
      if (result.isRight()) anySuccess = true;
    }

    if (anySuccess) {
      emit(TaskOperationSuccess('Tasks accepted and created'));
      add(LoadTasksEvent());
    } else {
      emit(TaskError('Failed to accept tasks'));
    }
  }
}
