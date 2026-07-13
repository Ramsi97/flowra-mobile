import 'package:bloc/bloc.dart';
import '../../domain/usecase/generate_schedule_usecase.dart';
import '../../domain/usecase/regenerate_schedule_usecase.dart';
import '../../domain/usecase/update_schedule_item_usecase.dart';
import '../../domain/usecase/delete_schedule_item_usecase.dart';
import '../../domain/usecase/clear_day_usecase.dart';
import '../../domain/usecase/clear_week_usecase.dart';
import '../../domain/usecase/clear_month_usecase.dart';
import '../../domain/usecase/fix_schedule_usecase.dart';
import '../../domain/usecase/ai_schedule_usecase.dart';
import '../../domain/entities/schedule_item.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final GenerateScheduleUseCase generateScheduleUseCase;
  final RegenerateScheduleUseCase regenerateScheduleUseCase;
  final UpdateScheduleItemUseCase updateScheduleItemUseCase;
  final DeleteScheduleItemUseCase deleteScheduleItemUseCase;
  final ClearDayUseCase clearDayUseCase;
  final ClearWeekUseCase clearWeekUseCase;
  final ClearMonthUseCase clearMonthUseCase;
  final FixScheduleUseCase fixScheduleUseCase;
  final AIScheduleUseCase aiScheduleUseCase;

  DateTime _selectedDate = DateTime.now();

  ScheduleBloc({
    required this.generateScheduleUseCase,
    required this.regenerateScheduleUseCase,
    required this.updateScheduleItemUseCase,
    required this.deleteScheduleItemUseCase,
    required this.clearDayUseCase,
    required this.clearWeekUseCase,
    required this.clearMonthUseCase,
    required this.fixScheduleUseCase,
    required this.aiScheduleUseCase,
  }) : super(ScheduleInitial()) {
    on<LoadScheduleEvent>(_onLoad);
    on<RegenerateScheduleEvent>(_onRegenerate);
    on<UpdateScheduleItemEvent>(_onUpdateItem);
    on<DeleteScheduleItemEvent>(_onDeleteItem);
    on<ClearDayEvent>(_onClearDay);
    on<ClearWeekEvent>(_onClearWeek);
    on<ClearMonthEvent>(_onClearMonth);
    on<FixScheduleEvent>(_onFix);
    on<AIScheduleEvent>(_onAISchedule);
    on<ChangeDateEvent>(_onChangeDate);
  }

  List<ScheduleItem>? get _currentItems {
    if (state is ScheduleLoaded) return (state as ScheduleLoaded).items;
    if (state is ScheduleLoading) return (state as ScheduleLoading).preservedItems;
    return null;
  }

  Future<void> _onLoad(LoadScheduleEvent event, Emitter<ScheduleState> emit) async {
    final preserved = _currentItems;
    // Parse before emitting loading so a malformed date can't strand the
    // spinner with no terminal state.
    final String dateStr;
    try {
      dateStr = _dateToString(DateTime.parse(event.date));
    } catch (_) {
      emit(ScheduleError('Invalid date: ${event.date}', preservedItems: preserved));
      return;
    }
    if (preserved == null) emit(const ScheduleLoading());
    final result = await generateScheduleUseCase(dateStr);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: preserved)),
      (items) => emit(ScheduleLoaded(items, selectedDate: _selectedDate)),
    );
  }

  Future<void> _onRegenerate(RegenerateScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading(preservedItems: _currentItems));
    final result = await regenerateScheduleUseCase(event.date);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: _currentItems)),
      (items) => emit(ScheduleLoaded(items, selectedDate: _selectedDate)),
    );
  }

  Future<void> _onUpdateItem(UpdateScheduleItemEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading(preservedItems: _currentItems));
    final result = await updateScheduleItemUseCase(event.itemId, event.updates);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: _currentItems)),
      (items) {
        emit(ScheduleOperationSuccess('Schedule updated', updatedItems: items));
        emit(ScheduleLoaded(items, selectedDate: _selectedDate));
      },
    );
  }

  Future<void> _onDeleteItem(DeleteScheduleItemEvent event, Emitter<ScheduleState> emit) async {
    final preserved = _currentItems;
    emit(ScheduleLoading(preservedItems: preserved));
    final result = await deleteScheduleItemUseCase(event.itemId);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: preserved)),
      (_) {
        final updated = preserved?.where((i) => i.id != event.itemId).toList() ?? [];
        emit(ScheduleOperationSuccess('Item removed'));
        emit(ScheduleLoaded(updated, selectedDate: _selectedDate));
      },
    );
  }

  Future<void> _onClearDay(ClearDayEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading(preservedItems: _currentItems));
    final result = await clearDayUseCase(event.date);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: _currentItems)),
      (_) {
        emit(const ScheduleOperationSuccess('Day cleared'));
        emit(ScheduleLoaded(const [], selectedDate: _selectedDate));
      },
    );
  }

  Future<void> _onClearWeek(ClearWeekEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading(preservedItems: _currentItems));
    final result = await clearWeekUseCase(event.startDate);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: _currentItems)),
      (_) {
        emit(const ScheduleOperationSuccess('Week cleared'));
        emit(ScheduleLoaded(const [], selectedDate: _selectedDate));
      },
    );
  }

  Future<void> _onClearMonth(ClearMonthEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading(preservedItems: _currentItems));
    final result = await clearMonthUseCase(event.month);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: _currentItems)),
      (_) {
        emit(const ScheduleOperationSuccess('Month cleared'));
        emit(ScheduleLoaded(const [], selectedDate: _selectedDate));
      },
    );
  }

  Future<void> _onFix(FixScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading(preservedItems: _currentItems));
    final result = await fixScheduleUseCase(event.currentTime);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: _currentItems)),
      (items) {
        emit(const ScheduleOperationSuccess('Schedule fixed'));
        emit(ScheduleLoaded(items, selectedDate: _selectedDate));
      },
    );
  }

  Future<void> _onAISchedule(AIScheduleEvent event, Emitter<ScheduleState> emit) async {
    emit(ScheduleLoading(preservedItems: _currentItems));
    final result = await aiScheduleUseCase(event.date, event.prompt);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString(), preservedItems: _currentItems)),
      (items) => emit(ScheduleLoaded(items, selectedDate: _selectedDate)),
    );
  }

  void _onChangeDate(ChangeDateEvent event, Emitter<ScheduleState> emit) {
    _selectedDate = event.date;
    add(LoadScheduleEvent(_dateToString(event.date)));
  }

  String _dateToString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
