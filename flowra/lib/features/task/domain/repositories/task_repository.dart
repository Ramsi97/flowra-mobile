import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../entities/task.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasks();
  Future<Either<Failure, Task>> createTask(Task task);
  Future<Either<Failure, Task>> updateTask(String id, Map<String, dynamic> updates);
  Future<Either<Failure, void>> deleteTask(String id);
  
  // AI Suggestions
  Future<Either<Failure, List<Task>>> suggestTasks(String description);
  Future<Either<Failure, List<Task>>> refineTasks(List<Task> drafts, String instruction);
}
