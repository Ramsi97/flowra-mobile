import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/focus_status.dart';
import '../../domain/repositories/focus_repository.dart';
import '../datasources/focus_remote_datasource.dart';

class FocusRepositoryImpl implements FocusRepository {
  final FocusRemoteDataSource remoteDataSource;

  FocusRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, FocusStatus>> getStatus() async {
    try {
      final status = await remoteDataSource.getStatus();
      return Right(status);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateConfig({
    List<String>? blockedApps,
    bool? focusModeEnabled,
  }) async {
    try {
      await remoteDataSource.updateConfig(
        blockedApps: blockedApps,
        focusModeEnabled: focusModeEnabled,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
