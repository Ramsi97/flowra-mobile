import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/schedule_item.dart';
import '../repositories/schedule_repository.dart';

class GenerateScheduleUseCase {
  final ScheduleRepository repository;
  GenerateScheduleUseCase(this.repository);

  Future<Either<Failure, List<ScheduleItem>>> call(String date) {
    return repository.generateSchedule(date);
  }
}
