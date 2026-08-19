import 'dart:async';
import 'dart:io';

import '../../features/auth/presentation/bloc/bloc/auth_bloc.dart';
import '../../features/focus/domain/entities/focus_status.dart';
import '../../features/focus/presentation/bloc/focus_bloc.dart';
import '../../features/focus/presentation/bloc/focus_state.dart';
import '../../features/schedule/domain/usecase/generate_schedule_usecase.dart';
import '../../features/schedule/presentation/bloc/schedule_bloc.dart';
import 'focus_blocker_service.dart';
import 'installed_apps_service.dart';

/// Keeps the native Android blocker's policy in sync with app state.
///
/// It watches three singleton blocs — focus (enabled flag + blocked apps),
/// schedule (which drives the focus windows), and auth (logout clears
/// everything) — and, debounced, pushes a fresh policy down to
/// [FocusBlockerService]. The native service then enforces entirely on its own,
/// even after the Flutter engine is gone.
///
/// Android-only: [start] no-ops elsewhere, so no streams are watched and no
/// platform channels are touched on iOS.
class FocusEnforcementCoordinator {
  FocusEnforcementCoordinator({
    required FocusBloc focusBloc,
    required ScheduleBloc scheduleBloc,
    required AuthBloc authBloc,
    required GenerateScheduleUseCase generateScheduleUseCase,
    required InstalledAppsService installedAppsService,
    required FocusBlockerService blockerService,
  })  : _focusBloc = focusBloc,
        _scheduleBloc = scheduleBloc,
        _authBloc = authBloc,
        _generateScheduleUseCase = generateScheduleUseCase,
        _installedAppsService = installedAppsService,
        _blockerService = blockerService;

  /// Our own package — never enforce against ourselves even if it somehow lands
  /// in the resolved set (the native service also guards this).
  static const String _ownPackage = 'com.example.flowra';

  /// Collapse bursts of bloc emissions (optimistic update + reload, etc.) into
  /// a single policy push.
  static const Duration _debounce = Duration(milliseconds: 700);

  final FocusBloc _focusBloc;
  final ScheduleBloc _scheduleBloc;
  final AuthBloc _authBloc;
  final GenerateScheduleUseCase _generateScheduleUseCase;
  final InstalledAppsService _installedAppsService;
  final FocusBlockerService _blockerService;

  StreamSubscription<Object?>? _focusSub;
  StreamSubscription<Object?>? _scheduleSub;
  StreamSubscription<Object?>? _authSub;
  Timer? _debounceTimer;

  /// Last successfully-computed windows, reused when a schedule fetch fails so a
  /// transient network blip doesn't drop active enforcement.
  List<FocusPolicyWindow> _lastWindows = const [];

  bool _started = false;

  /// Begin watching app state and syncing policy. Safe to call once at startup.
  void start() {
    if (_started || !Platform.isAndroid) return;
    _started = true;

    _focusSub = _focusBloc.stream.listen((_) => _scheduleSync());
    _scheduleSub = _scheduleBloc.stream.listen((_) => _scheduleSync());
    _authSub = _authBloc.stream.listen(_onAuthState);

    // Kick an initial sync; if focus status hasn't loaded yet this no-ops and a
    // later FocusLoaded emission will drive the real push.
    _scheduleSync();
  }

  void _onAuthState(Object? state) {
    if (state is AuthUnauthenticated) {
      // Logged out / session expired — tear enforcement down immediately.
      _debounceTimer?.cancel();
      _lastWindows = const [];
      unawaited(_blockerService.clearPolicy());
    }
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => unawaited(_sync()));
  }

  Future<void> _sync() async {
    if (!Platform.isAndroid) return;

    final status = _focusStatus;
    // Null means we don't yet know the real state (fresh launch / loading). Do
    // NOT clear here — that would wipe a valid policy the native service may be
    // enforcing from a previous run before we've confirmed anything.
    if (status == null) return;

    if (!status.focusModeEnabled || status.blockedApps.isEmpty) {
      _lastWindows = const [];
      await _blockerService.clearPolicy();
      return;
    }

    final packages =
        await _installedAppsService.resolvePackages(status.blockedApps);
    packages.remove(_ownPackage);
    if (packages.isEmpty) {
      // Nothing installed maps to the chosen names — nothing to enforce.
      await _blockerService.clearPolicy();
      return;
    }

    final windows = await _todaysWindows();
    await _blockerService.updatePolicy(
      enabled: true,
      packages: packages,
      windows: windows,
      blockStyle: FocusBlockStyle.overlay,
    );
  }

  /// Today's schedule items (minus done/skipped) as absolute epoch windows.
  /// On fetch failure, returns the last-good set so enforcement survives blips.
  Future<List<FocusPolicyWindow>> _todaysWindows() async {
    final result = await _generateScheduleUseCase(_todayString());
    return result.fold(
      (_) => _lastWindows,
      (items) {
        final windows = <FocusPolicyWindow>[];
        for (final item in items) {
          if (item.status == 'done' || item.status == 'skipped') continue;
          windows.add(FocusPolicyWindow(
            startMs: item.startTime.millisecondsSinceEpoch,
            endMs: item.endTime.millisecondsSinceEpoch,
            title: item.title,
          ));
        }
        _lastWindows = windows;
        return windows;
      },
    );
  }

  FocusStatus? get _focusStatus {
    final s = _focusBloc.state;
    if (s is FocusLoaded) return s.status;
    if (s is FocusLoading) return s.preserved;
    if (s is FocusError) return s.preserved;
    return null;
  }

  String _todayString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Not used in normal app life (the coordinator is an app-lifetime singleton),
  /// but tears down cleanly if ever needed.
  void dispose() {
    _focusSub?.cancel();
    _scheduleSub?.cancel();
    _authSub?.cancel();
    _debounceTimer?.cancel();
    _started = false;
  }
}
