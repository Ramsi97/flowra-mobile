import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/schedule_item.dart';
import '../repositories/schedule_repository.dart';

class RegenerateScheduleUseCase {
  final ScheduleRepository repository;
  RegenerateScheduleUseCase(this.repository);

  Future<Either<Failure, List<ScheduleItem>>> call(String date) {
    return repository.regenerateSchedule(date);
  }
}
