import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/schedule_repository.dart';

class ClearMonthUseCase {
  final ScheduleRepository repository;
  ClearMonthUseCase(this.repository);

  Future<Either<Failure, void>> call(String month) {
    return repository.clearMonth(month);
  }
}
