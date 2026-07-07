import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/focus_status.dart';
import '../repositories/focus_repository.dart';

class GetFocusStatusUseCase {
  final FocusRepository repository;
  GetFocusStatusUseCase(this.repository);

  Future<Either<Failure, FocusStatus>> call() {
    return repository.getStatus();
  }
}
