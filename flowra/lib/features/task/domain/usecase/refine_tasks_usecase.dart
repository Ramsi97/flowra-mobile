import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class RefineTasksUseCase {
  final TaskRepository repository;
  RefineTasksUseCase(this.repository);

  Future<Either<Failure, List<Task>>> call(List<Task> drafts, String instruction) =>
      repository.refineTasks(drafts, instruction);
}
