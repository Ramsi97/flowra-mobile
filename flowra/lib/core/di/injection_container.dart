import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecase/login_usecase.dart';
import '../../features/auth/domain/usecase/register_usecase.dart';
import '../../features/auth/domain/usecase/logout_usecase.dart';
import '../../features/auth/domain/usecase/check_auth_usecase.dart';
import '../../features/auth/domain/usecase/update_profile_usecase.dart';
import '../../features/auth/presentation/bloc/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/profile/profile_bloc.dart';
import '../network/api_client.dart';
import 'package:flowra/features/task/data/datasources/task_remote_datasource.dart';
import 'package:flowra/features/task/data/repositories/task_repository_impl.dart';
import 'package:flowra/features/task/domain/repositories/task_repository.dart';
import 'package:flowra/features/task/domain/usecase/get_tasks_usecase.dart';
import 'package:flowra/features/task/domain/usecase/create_task_usecase.dart';
import 'package:flowra/features/task/domain/usecase/update_task_usecase.dart';
import 'package:flowra/features/task/domain/usecase/delete_task_usecase.dart';
import 'package:flowra/features/task/domain/usecase/suggest_tasks_usecase.dart';
import 'package:flowra/features/task/domain/usecase/refine_tasks_usecase.dart';
import 'package:flowra/features/task/presentation/bloc/task_bloc.dart';
import 'package:flowra/features/settings/presentation/bloc/theme_bloc.dart';
import 'package:flowra/features/task/data/datasources/task_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Schedule Feature Imports
import 'package:flowra/features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:flowra/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:flowra/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:flowra/features/schedule/domain/usecase/generate_schedule_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/regenerate_schedule_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/update_schedule_item_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/delete_schedule_item_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/clear_day_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/clear_week_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/clear_month_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/fix_schedule_usecase.dart';
import 'package:flowra/features/schedule/domain/usecase/ai_schedule_usecase.dart';
import 'package:flowra/features/schedule/presentation/bloc/schedule_bloc.dart';

// Focus Feature Imports
import 'package:flowra/features/focus/data/datasources/focus_remote_datasource.dart';
import 'package:flowra/features/focus/data/repositories/focus_repository_impl.dart';
import 'package:flowra/features/focus/domain/repositories/focus_repository.dart';
import 'package:flowra/features/focus/domain/usecase/get_focus_status_usecase.dart';
import 'package:flowra/features/focus/domain/usecase/update_focus_config_usecase.dart';
import 'package:flowra/features/focus/presentation/bloc/focus_bloc.dart';

// Core device services (focus enforcement)
import '../services/installed_apps_service.dart';
import '../services/focus_blocker_service.dart';
import '../services/focus_enforcement_coordinator.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Core ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // SharedPreferences (must be awaited before use)
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // ── Auth – Data ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasource(sl<ApiClient>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDatasource>()),
  );

  // ── Task – Data ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(prefs: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      remoteDataSource: sl<TaskRemoteDataSource>(),
      localDataSource: sl<TaskLocalDataSource>(),
    ),
  );

  // ── Schedule – Data ───────────────────────────────────────────────────────
  sl.registerLazySingleton<ScheduleRemoteDataSource>(
    () => ScheduleRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(remoteDataSource: sl<ScheduleRemoteDataSource>()),
  );

  // ── Focus – Data ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<FocusRemoteDataSource>(
    () => FocusRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  sl.registerLazySingleton<FocusRepository>(
    () => FocusRepositoryImpl(remoteDataSource: sl<FocusRemoteDataSource>()),
  );

  // ── Task – Use Cases ─────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetTasksUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => SuggestTasksUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => RefineTasksUseCase(sl<TaskRepository>()));

  // ── Schedule – Use Cases ──────────────────────────────────────────────────
  sl.registerLazySingleton(() => GenerateScheduleUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => RegenerateScheduleUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => UpdateScheduleItemUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => DeleteScheduleItemUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => ClearDayUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => ClearWeekUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => ClearMonthUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => FixScheduleUseCase(sl<ScheduleRepository>()));
  sl.registerLazySingleton(() => AIScheduleUseCase(sl<ScheduleRepository>()));

  // ── Focus – Use Cases ─────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetFocusStatusUseCase(sl<FocusRepository>()));
  sl.registerLazySingleton(() => UpdateFocusConfigUseCase(sl<FocusRepository>()));

  // ── Auth – Use Cases ─────────────────────────────────────────────────────
  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => CheckAuthUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => UpdateProfileUseCase(sl<AuthRepository>()));

  // ── Auth – BLoC ──────────────────────────────────────────────────────────
  // Singleton (not factory): the root BlocProvider creates the one instance the
  // whole app uses, and FocusEnforcementCoordinator listens to that same stream.
  sl.registerLazySingleton(() => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        checkAuthUseCase: sl<CheckAuthUseCase>(),
      ));

  sl.registerFactory(() => ProfileBloc(
        updateProfileUseCase: sl<UpdateProfileUseCase>(),
      ));

  // ── Task – BLoC ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => TaskBloc(
        getTasksUseCase: sl<GetTasksUseCase>(),
        createTaskUseCase: sl<CreateTaskUseCase>(),
        updateTaskUseCase: sl<UpdateTaskUseCase>(),
        deleteTaskUseCase: sl<DeleteTaskUseCase>(),
        suggestTasksUseCase: sl<SuggestTasksUseCase>(),
        refineTasksUseCase: sl<RefineTasksUseCase>(),
      ));

  // ── Schedule – BLoC ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ScheduleBloc(
        generateScheduleUseCase: sl<GenerateScheduleUseCase>(),
        regenerateScheduleUseCase: sl<RegenerateScheduleUseCase>(),
        updateScheduleItemUseCase: sl<UpdateScheduleItemUseCase>(),
        deleteScheduleItemUseCase: sl<DeleteScheduleItemUseCase>(),
        clearDayUseCase: sl<ClearDayUseCase>(),
        clearWeekUseCase: sl<ClearWeekUseCase>(),
        clearMonthUseCase: sl<ClearMonthUseCase>(),
        fixScheduleUseCase: sl<FixScheduleUseCase>(),
        aiScheduleUseCase: sl<AIScheduleUseCase>(),
      ));

  // ── Focus – BLoC ──────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => FocusBloc(
        getFocusStatusUseCase: sl<GetFocusStatusUseCase>(),
        updateFocusConfigUseCase: sl<UpdateFocusConfigUseCase>(),
      ));

  // ── Settings – BLoC ──────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ThemeBloc(prefs: sl<SharedPreferences>()));

  // ── Focus enforcement (Android) ──────────────────────────────────────────
  sl.registerLazySingleton(() => const InstalledAppsService());
  sl.registerLazySingleton(() => FocusBlockerService());
  sl.registerLazySingleton(() => FocusEnforcementCoordinator(
        focusBloc: sl<FocusBloc>(),
        scheduleBloc: sl<ScheduleBloc>(),
        authBloc: sl<AuthBloc>(),
        generateScheduleUseCase: sl<GenerateScheduleUseCase>(),
        installedAppsService: sl<InstalledAppsService>(),
        blockerService: sl<FocusBlockerService>(),
      ));
}

