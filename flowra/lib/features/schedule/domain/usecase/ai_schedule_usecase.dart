import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/schedule_item.dart';
import '../repositories/schedule_repository.dart';

class AIScheduleUseCase {
  final ScheduleRepository repository;
  AIScheduleUseCase(this.repository);

  Future<Either<Failure, List<ScheduleItem>>> call(
    String date,
    String prompt,
  ) {
    return repository.aiSchedule(date, prompt);
  }
}
