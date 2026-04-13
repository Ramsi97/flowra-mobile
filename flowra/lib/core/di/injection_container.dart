import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecase/login_usecase.dart';
import '../../features/auth/domain/usecase/register_usecase.dart';
import '../../features/auth/domain/usecase/logout_usecase.dart';
import '../../features/auth/presentation/bloc/bloc/auth_bloc.dart';
import '../network/api_client.dart';
import 'package:flowra/features/task/data/datasources/task_remote_datasource.dart';
import 'package:flowra/features/task/data/repositories/task_repository_impl.dart';
import 'package:flowra/features/task/domain/repositories/task_repository.dart';
import 'package:flowra/features/task/presentation/bloc/task_bloc.dart';

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

  // ── Auth – Use Cases ─────────────────────────────────────────────────────
  sl.registerFactory(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerFactory(() => LogoutUseCase(sl<AuthRepository>()));

  // ── Auth – BLoC ──────────────────────────────────────────────────────────
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
      ));

  // ── Task – BLoC ──────────────────────────────────────────────────────────
  sl.registerFactory(() => TaskBloc(repository: sl<TaskRepository>()));
}
