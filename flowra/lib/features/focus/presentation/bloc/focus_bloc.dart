import 'package:bloc/bloc.dart';
import '../../domain/entities/focus_status.dart';
import '../../domain/usecase/get_focus_status_usecase.dart';
import '../../domain/usecase/update_focus_config_usecase.dart';
import 'focus_event.dart';
import 'focus_state.dart';

class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final GetFocusStatusUseCase getFocusStatusUseCase;
  final UpdateFocusConfigUseCase updateFocusConfigUseCase;

  FocusBloc({
    required this.getFocusStatusUseCase,
    required this.updateFocusConfigUseCase,
  }) : super(const FocusInitial()) {
    on<LoadFocusStatusEvent>(_onLoad);
    on<ToggleFocusModeEvent>(_onToggle);
    on<AddBlockedAppEvent>(_onAddApp);
    on<RemoveBlockedAppEvent>(_onRemoveApp);
    on<SetBlockedAppsEvent>(_onSetApps);
  }

  FocusStatus? get _current {
    final s = state;
    if (s is FocusLoaded) return s.status;
    if (s is FocusLoading) return s.preserved;
    if (s is FocusError) return s.preserved;
    return null;
  }

  Future<void> _onLoad(LoadFocusStatusEvent event, Emitter<FocusState> emit) async {
    emit(FocusLoading(preserved: _current));
    final result = await getFocusStatusUseCase();
    result.fold(
      (failure) => emit(FocusError(failure.message, preserved: _current)),
      (status) => emit(FocusLoaded(status)),
    );
  }

  Future<void> _onToggle(ToggleFocusModeEvent event, Emitter<FocusState> emit) async {
    final base = _current;
    // Optimistic update so the switch reacts instantly.
    if (base != null) {
      emit(FocusLoaded(base.copyWith(focusModeEnabled: event.enabled)));
    }
    final result =
        await updateFocusConfigUseCase(focusModeEnabled: event.enabled);
    await result.fold(
      (failure) async {
        if (base != null) emit(FocusLoaded(base));
        emit(FocusError(failure.message, preserved: base));
      },
      (_) async => add(const LoadFocusStatusEvent()),
    );
  }

  Future<void> _onAddApp(AddBlockedAppEvent event, Emitter<FocusState> emit) async {
    final base = _current;
    final app = event.app.trim();
    if (base == null || app.isEmpty || base.blockedApps.contains(app)) return;
    final updated = [...base.blockedApps, app];
    emit(FocusLoaded(base.copyWith(blockedApps: updated)));
    final result = await updateFocusConfigUseCase(blockedApps: updated);
    result.fold(
      (failure) {
        emit(FocusLoaded(base));
        emit(FocusError(failure.message, preserved: base));
      },
      (_) {},
    );
  }

  Future<void> _onSetApps(SetBlockedAppsEvent event, Emitter<FocusState> emit) async {
    final base = _current;
    if (base == null) return;
    // De-dupe while preserving order.
    final seen = <String>{};
    final updated = <String>[];
    for (final app in event.apps) {
      final trimmed = app.trim();
      if (trimmed.isEmpty || !seen.add(trimmed.toLowerCase())) continue;
      updated.add(trimmed);
    }
    emit(FocusLoaded(base.copyWith(blockedApps: updated)));
    final result = await updateFocusConfigUseCase(blockedApps: updated);
    result.fold(
      (failure) {
        emit(FocusLoaded(base));
        emit(FocusError(failure.message, preserved: base));
      },
      (_) {},
    );
  }

  Future<void> _onRemoveApp(RemoveBlockedAppEvent event, Emitter<FocusState> emit) async {
    final base = _current;
    if (base == null) return;
    final updated =
        base.blockedApps.where((a) => a != event.app).toList();
    emit(FocusLoaded(base.copyWith(blockedApps: updated)));
    final result = await updateFocusConfigUseCase(blockedApps: updated);
    result.fold(
      (failure) {
        emit(FocusLoaded(base));
        emit(FocusError(failure.message, preserved: base));
      },
      (_) {},
    );
  }
}
