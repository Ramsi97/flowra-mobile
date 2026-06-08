import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecase/login_usecase.dart';
import '../../features/auth/domain/usecase/register_usecase.dart';
import '../../features/auth/domain/usecase/logout_usecase.dart';
import '../../features/auth/domain/usecase/check_auth_usecase.dart';
import '../../features/auth/presentation/bloc/bloc/auth_bloc.dart';
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

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── Core ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

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

  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(remoteDataSource: sl<TaskRemoteDataSource>()),
  );

  // ── Task – Use Cases ─────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetTasksUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => SuggestTasksUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => RefineTasksUseCase(sl<TaskRepository>()));

  // ── Auth – Use Cases ─────────────────────────────────────────────────────
  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => CheckAuthUseCase(sl<AuthRepository>()));

  // ── Auth – BLoC ──────────────────────────────────────────────────────────
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        checkAuthUseCase: sl<CheckAuthUseCase>(),
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

  // ── Settings – BLoC ──────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ThemeBloc());
}

