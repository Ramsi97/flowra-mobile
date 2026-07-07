import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/focus_repository.dart';

class UpdateFocusConfigUseCase {
  final FocusRepository repository;
  UpdateFocusConfigUseCase(this.repository);

  Future<Either<Failure, void>> call({
    List<String>? blockedApps,
    bool? focusModeEnabled,
  }) {
    return repository.updateConfig(
      blockedApps: blockedApps,
      focusModeEnabled: focusModeEnabled,
    );
  }
}
