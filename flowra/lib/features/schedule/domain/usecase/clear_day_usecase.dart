import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/schedule_repository.dart';

class ClearDayUseCase {
  final ScheduleRepository repository;
  ClearDayUseCase(this.repository);

  Future<Either<Failure, void>> call(String date) {
    return repository.clearDay(date);
  }
}
