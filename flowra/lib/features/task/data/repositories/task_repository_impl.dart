import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';
import '../model/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Task>>> getTasks() async {
    try {
      final models = await remoteDataSource.getTasks();
      return Right(List<Task>.from(models));
    } catch (e) {
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
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      final result = await remoteDataSource.updateTask(id, updates);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await remoteDataSource.deleteTask(id);
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
