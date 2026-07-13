import 'package:bloc/bloc.dart';

import '../../domain/usecase/get_tasks_usecase.dart';
import '../../domain/usecase/create_task_usecase.dart';
import '../../domain/usecase/update_task_usecase.dart';
import '../../domain/usecase/delete_task_usecase.dart';
import '../../domain/usecase/suggest_tasks_usecase.dart';
import '../../domain/usecase/refine_tasks_usecase.dart';
import 'task_event.dart';
import 'task_state.dart';
import '../../domain/entities/task.dart';

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
    final preserved = _currentTasks;
    final mode = _currentViewMode;
    if (preserved == null) {
      emit(TaskLoading(viewMode: mode));
    }
    final result = await getTasksUseCase(forceRefresh: event.forceRefresh);
    result.fold(
      (failure) => emit(TaskError(failure.toString())),
      (tasks) => emit(TasksLoaded(tasks, viewMode: mode)),
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
        emit(TaskOperationSuccess('Task created successfully', preservedTasks: preserved?.cast(), viewMode: mode));
        add(LoadTasksEvent());
      },
    );
  }

  Future<void> _onUpdateTask(UpdateTaskEvent event, Emitter<TaskState> emit) async {
    final preserved = _currentTasks?.cast<Task>();
    final mode = _currentViewMode;
    
    String successMessage = 'Task updated';
    if (event.updates.containsKey('status')) {
      successMessage = event.updates['status'] == 'done' 
          ? 'Task marked as done' 
          : 'Task marked as pending';
    }

    if (preserved != null) {
      final newTasks = List<Task>.from(preserved);
      final index = newTasks.indexWhere((t) => t.id == event.id);
      if (index != -1) {
        final currentTask = newTasks[index];
        newTasks[index] = currentTask.copyWith(
          status: event.updates['status'] as String?,
          title: event.updates['title'] as String?,
          description: event.updates['description'] as String?,
        );
        emit(TasksLoaded(newTasks, viewMode: mode));
      }
    }

    final result = await updateTaskUseCase(event.id, event.updates);
    result.fold(
      (failure) {
        if (preserved != null) {
          emit(TasksLoaded(preserved, viewMode: mode));
        }
        emit(TaskError(failure.toString()));
      },
      (task) {
        if (preserved != null) {
           final List<Task> finalTasks = List<Task>.from(preserved);
           final index = finalTasks.indexWhere((Task t) => t.id == event.id);
           if (index != -1) {
             finalTasks[index] = task;
           }
           emit(TasksLoaded(finalTasks, viewMode: mode));
        } else {
          // No list was loaded yet, so there's nothing to preserve. Pull the
          // list so the UI resolves to a real state instead of a stuck spinner.
          add(LoadTasksEvent());
        }
        emit(TaskOperationSuccess(successMessage, preservedTasks: _currentTasks?.cast(), viewMode: mode));
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
        emit(TaskOperationSuccess('Task deleted', preservedTasks: preserved?.cast(), viewMode: mode));
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
      emit(TaskOperationSuccess('Tasks accepted and created', preservedTasks: _currentTasks?.cast(), viewMode: _currentViewMode));
      add(LoadTasksEvent());
    } else {
      emit(TaskError('Failed to accept tasks'));
    }
  }
}
