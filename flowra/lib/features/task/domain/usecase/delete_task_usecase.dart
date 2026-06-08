import 'package:dartz/dartz.dart' hide Task;
import '../../../../core/error/failures.dart';
import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;
  DeleteTaskUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) => repository.deleteTask(id);
}
