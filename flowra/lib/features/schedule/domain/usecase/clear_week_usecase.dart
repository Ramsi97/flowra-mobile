import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/schedule_repository.dart';

class ClearWeekUseCase {
  final ScheduleRepository repository;
  ClearWeekUseCase(this.repository);

  Future<Either<Failure, void>> call(String startDate) {
    return repository.clearWeek(startDate);
  }
}
