import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/schedule_item.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;

  ScheduleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ScheduleItem>>> generateSchedule(
      String date) async {
    try {
      final items = await remoteDataSource.generateSchedule(date);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleItem>>> regenerateSchedule(
      String date) async {
    try {
      final items = await remoteDataSource.regenerateSchedule(date);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleItem>>> updateItem(
      String itemId, Map<String, dynamic> updates) async {
    try {
      final items = await remoteDataSource.updateItem(itemId, updates);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(String itemId) async {
    try {
      await remoteDataSource.deleteItem(itemId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearDay(String date) async {
    try {
      await remoteDataSource.clearDay(date);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearWeek(String startDate) async {
    try {
      await remoteDataSource.clearWeek(startDate);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearMonth(String month) async {
    try {
      await remoteDataSource.clearMonth(month);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleItem>>> fixSchedule(
      String currentTime) async {
    try {
      final items = await remoteDataSource.fixSchedule(currentTime);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeTaskFromSchedule(String itemId) async {
    try {
      await remoteDataSource.removeTaskFromSchedule(itemId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScheduleItem>>> aiSchedule(
      String date, String prompt) async {
    try {
      final items = await remoteDataSource.aiSchedule(date, prompt);
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
