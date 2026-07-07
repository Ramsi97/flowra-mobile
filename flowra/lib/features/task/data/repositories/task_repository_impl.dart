import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../model/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Task>>> getTasks({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      try {
        final cached = await localDataSource.getCachedTasks();
        if (cached.isNotEmpty) {
          return Right(List<Task>.from(cached));
        }
      } catch (_) {
        // Fall through to remote on cache read failure
      }
    }

    try {
      final models = await remoteDataSource.getTasks();
      // Save to local cache for next time
      await localDataSource.cacheTasks(models.cast<TaskModel>());
      return Right(List<Task>.from(models));
    } catch (e) {
      // If network fails, try cache as fallback
      try {
        final cached = await localDataSource.getCachedTasks();
        if (cached.isNotEmpty) return Right(List<Task>.from(cached));
      } catch (_) {}
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      final model = TaskModel(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        duration: task.duration,
        priority: task.priority,
        isHard: task.isHard,
        status: task.status,
        deadline: task.deadline,
      );
      final result = await remoteDataSource.createTask(model);
      // After creating, refresh cache from server
      final allModels = await remoteDataSource.getTasks();
      await localDataSource.cacheTasks(allModels.cast<TaskModel>());
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      final result = await remoteDataSource.updateTask(id, updates);
      // Update only the specific task in cache
      try {
        final cached = await localDataSource.getCachedTasks();
        final index = cached.indexWhere((t) => t.id == id);
        if (index != -1) {
          cached[index] = result;
          await localDataSource.cacheTasks(cached);
        }
      } catch (_) {}
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await remoteDataSource.deleteTask(id);
      // Remove from local cache
      try {
        final cached = await localDataSource.getCachedTasks();
        cached.removeWhere((t) => t.id == id);
        await localDataSource.cacheTasks(cached);
      } catch (_) {}
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> suggestTasks(String description) async {
    try {
      final models = await remoteDataSource.suggestTasks(description);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> refineTasks(List<Task> drafts, String instruction) async {
    try {
      final result = await remoteDataSource.refineTasks(
        drafts.map((e) => TaskModel(
          id: e.id,
          userId: e.userId,
          title: e.title,
          description: e.description,
          duration: e.duration,
          priority: e.priority,
          isHard: e.isHard,
          status: e.status,
          deadline: e.deadline,
        )).toList(),
        instruction,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
