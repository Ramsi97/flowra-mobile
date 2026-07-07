import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/focus_status.dart';

abstract class FocusRepository {
  Future<Either<Failure, FocusStatus>> getStatus();

  /// Updates focus preferences. Either field may be null to leave it unchanged.
  Future<Either<Failure, void>> updateConfig({
    List<String>? blockedApps,
    bool? focusModeEnabled,
  });
}
