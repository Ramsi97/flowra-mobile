import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/schedule_item.dart';
import '../repositories/schedule_repository.dart';

class FixScheduleUseCase {
  final ScheduleRepository repository;
  FixScheduleUseCase(this.repository);

  Future<Either<Failure, List<ScheduleItem>>> call(String currentTime) {
    return repository.fixSchedule(currentTime);
  }
}
