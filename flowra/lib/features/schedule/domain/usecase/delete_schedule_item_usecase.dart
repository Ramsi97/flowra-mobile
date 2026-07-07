import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/schedule_repository.dart';

class DeleteScheduleItemUseCase {
  final ScheduleRepository repository;
  DeleteScheduleItemUseCase(this.repository);

  Future<Either<Failure, void>> call(String itemId) {
    return repository.deleteItem(itemId);
  }
}
