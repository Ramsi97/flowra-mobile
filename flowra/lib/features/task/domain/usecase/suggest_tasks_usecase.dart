import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class SuggestTasksUseCase {
  final TaskRepository repository;
  SuggestTasksUseCase(this.repository);

  Future<Either<Failure, List<Task>>> call(String description) =>
      repository.suggestTasks(description);
}
