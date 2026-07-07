import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/schedule_item.dart';
import '../repositories/schedule_repository.dart';

class UpdateScheduleItemUseCase {
  final ScheduleRepository repository;
  UpdateScheduleItemUseCase(this.repository);

  Future<Either<Failure, List<ScheduleItem>>> call(
    String itemId,
    Map<String, dynamic> updates,
  ) {
    return repository.updateItem(itemId, updates);
  }
}
